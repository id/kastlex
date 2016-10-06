defmodule Kastlex.CgCache do
  require Logger

  @table  :consumer_groups
  @server __MODULE__

  @refresh_hwm_offsets :refresh_hwm_offsets
  @offset :commited_offset
  @cg_status :new_cg_status

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: @server])
  end

  def get_groups() do
    :ets.select(@table, [{{:"$1", :"_"}, [], [:"$1"]}])
  end

  def get_group(group_id) do
    ets_lookup(@table, group_id, false)
  end

  def refresh_hwm_offsets() do
    GenServer.cast(@server, @refresh_hwm_offsets)
  end

  def commited_offset(key, value) do
    GenServer.cast(@server, {@offset, key, value})
  end

  def new_cg_status(key, value) do
    GenServer.cast(@server, {@cg_status, key, value})
  end

  def init(_options) do
    :ets.new(@table, [:set, :protected, :named_table, {:read_concurrency, true}])
    {:ok, %{}}
  end

  def handle_cast({@offset, key, value}, state) do
    group_id = key[:group_id]
    topic = key[:topic]
    partition = key[:partition]
    group = ets_lookup(@table, group_id, %{:group_id => group_id}) |>
      Map.update(:partitions, [],
                 fn(x) ->
                   keys = [:offset, :timestamp, :metadata, :commit_time, :expire_time]
                   data = keyfind(topic, partition, x) |>
                     kv_to_map(keys, value)
                   keystore(topic, partition, x, data)
                 end)
    :ets.insert(@table, {group_id, group})
    {:noreply, state}
  end

  def handle_cast({@cg_status, _key, []}, state), do: {:noreply, state}
  def handle_cast({@cg_status, key, value}, state) do
    group_id = key[:group_id]
    members = Keyword.get(value, :members, []) |> Enum.map(&to_maps(&1))
    group = ets_lookup(@table, group_id, %{:group_id => group_id}) |>
      Map.put(:generation_id, value[:generation_id]) |>
      Map.put(:leader, value[:leader]) |>
      Map.put(:protocol, value[:protocol]) |>
      Map.put(:members, members)
    :ets.insert(@table, {group_id, group})
    {:noreply, state}
  end

  def handle_cast(@refresh_hwm_offsets, state) do
    get_ets_keys_lazy(@table)
      |> Stream.map(&update_group_hwm_offsets(&1))
      |> Stream.run
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error "Unexpected msg: #{msg}"
    {:noreply, state}
  end

  def terminate(reason, _state) do
    Logger.info "#{inspect Kernel.self} is terminating: #{inspect reason}"
  end

  defp update_group_hwm_offsets(group_id) do
    [{_, group}] = :ets.lookup(@table, group_id)
    f = fn(list) ->
      Enum.map(list, fn(x) ->
                 hwm_offset = Kastlex.OffsetsCache.get_hwm_offset(x.topic, x.partition)
                 Map.put(x, :high_wm_offset, hwm_offset)
               end)
    end
    group = Map.update(group, :partitions, [], f)
    :ets.insert(@table, {group_id, group})
  end

  # a custom version of lists:keytake/3,4
  defp keyfind(topic, partition, []) do
    %{:topic => topic, :partition => partition}
  end
  defp keyfind(topic, partition, [h | tail]) do
    case h.topic == topic && h.partition == partition do
      true -> h
      false -> keyfind(topic, partition, tail)
    end
  end

  # a custom version of lists:keystore/4
  defp keystore(_topic, _partition, [], new), do: [new]
  defp keystore(topic, partition, [h | tail], new) do
    case h.topic == topic && h.partition == partition do
      true -> [new | tail]
      false -> [h | keystore(topic, partition, tail, new)]
    end
  end

  defp kv_to_map(map, [], _kv), do: map
  defp kv_to_map(map, [key | keys], kv) do
    case Keyword.has_key?(kv, key) do
      true -> kv_to_map(Map.put(map, key, kv[key]), keys, kv)
      false -> kv_to_map(map, keys, kv)
    end
  end

  defp ets_lookup(table, key, default) do
    case :ets.lookup(table, key) do
      [] -> default
      [{_, value}] -> value
    end
  end

  defp get_ets_keys_lazy(table_name) when is_atom(table_name) do
    eot = :"$end_of_table"

    Stream.resource(
      fn -> [] end,

      fn acc ->
        case acc do
          [] ->
            case :ets.first(table_name) do
              ^eot -> {:halt, acc}
              first_key -> {[first_key], first_key}
            end

          acc ->
            case :ets.next(table_name, acc) do
              ^eot -> {:halt, acc}
              next_key -> {[next_key], next_key}
            end
        end
      end,

      fn _acc -> :ok end
    )
  end

  defp to_maps({k, [x | _] = v}) when is_list(x), do: {k, :lists.map(&to_maps/1, v)}
  defp to_maps({k, [x | _] = v}) when is_tuple(x), do: {k, Map.new(v, &to_maps/1)}
  defp to_maps([{_, _} | _] = x), do: Map.new(:lists.map(&to_maps/1, x))
  defp to_maps({k, v}), do: {k, v}

end

