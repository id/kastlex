defmodule Kastlex.MetadataCache do
  require Logger

  use GenServer

  @table __MODULE__
  @server __MODULE__
  @refresh :refresh

  def get_brokers() do
    [{:ts, ts}] = :ets.lookup(@table, :ts)
    [{:brokers, brokers}] = :ets.lookup(@table, :brokers)
    {:ok, ts, brokers}
  end

  def get_topics() do
    [{:ts, ts}] = :ets.lookup(@table, :ts)
    [{:topics, topics}] = :ets.lookup(@table, :topics)
    {:ok, ts, topics}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: @server])
  end

  def init(:ok) do
    :ets.new(@table, [:set, :protected, :named_table])
    :ets.insert(@table, {:ts, :erlang.system_time()})
    :ets.insert(@table, {:brokers, []})
    :ets.insert(@table, {:topics, []})
    env = Application.get_env(:kastlex, __MODULE__)
    refresh_timeout_ms = Keyword.fetch!(env, :refresh_timeout_ms)
    :erlang.send_after(0, Kernel.self(), @refresh)
    {:ok, %{refresh_timeout_ms: refresh_timeout_ms}}
  end

  def handle_info(@refresh, state) do
    {:ok, {:kpro_MetadataResponse, brokers, topics}} = :brod_client.get_metadata(:kastlex, :undefined)
    :ets.insert(@table, {:ts, :erlang.system_time()})
    :ets.insert(@table, {:brokers, brokers_metadata_to_map(brokers)})
    :ets.insert(@table, {:topics, topics_metadata_to_map(topics)})
    :erlang.send_after(state.refresh_timeout_ms, Kernel.self(), @refresh)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warning "Unexpected msg: #{msg}"
    {:noreply, state}
  end

  defp brokers_metadata_to_map(brokers), do: brokers_metadata_to_map(brokers, [])

  defp brokers_metadata_to_map([], acc), do: acc
  defp brokers_metadata_to_map([broker | tail], acc) do
    {:kpro_Broker, id, host, port} = broker
    brokers_metadata_to_map(tail, [%{id: id, host: host, port: port} | acc])
  end

  defp topics_metadata_to_map(topics), do: topics_metadata_to_map(topics, [])

  defp topics_metadata_to_map([], acc), do: acc
  defp topics_metadata_to_map([{:kpro_TopicMetadata, error_code, topic, partitions} | tail], acc) do
    topics_metadata_to_map(tail, [%{topic: topic,
                                    error_code: error_code,
                                    partitions: partition_metadata_to_map(partitions)} | acc])
  end

  defp partition_metadata_to_map(partitions) do
    partition_metadata_to_map(partitions, [])
  end

  defp partition_metadata_to_map([], acc), do: acc
  defp partition_metadata_to_map([p | tail], acc) do
    {:kpro_PartitionMetadata, error_code, partition, leader, replicas, isr} = p
    partition_metadata_to_map(tail, [%{partition: partition,
                                       error_code: error_code,
                                       leader: leader,
                                       replicas: replicas,
                                       isr: isr} | acc])
  end
end
