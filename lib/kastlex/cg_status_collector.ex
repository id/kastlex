defmodule Kastlex.CgStatusCollector do
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :kafka_message,
             extract(:kafka_message, from_lib: "brod/include/brod.hrl")

  @behaviour :brod_topic_subscriber

  @table :consumer_offsets
  @topic "__consumer_offsets"
  @server __MODULE__

  def get_groups() do
    Enum.filter(
      :ets.tab2list(@table),
      fn({key, _value}) -> get_type(key) === :group end)
  end

  def get_offsets() do
    Enum.filter(
      :ets.tab2list(@table),
      fn({key, _value}) -> get_type(key) === :offset end)
  end

  def start_link(options) do
    client = options.brod_client_id
    consumer_config = [{:begin_offset, :earliest}]
    ## start a topic subscriber which will spawn one consumer process
    ## for each partition, and subscribe to all partition consumers
    :brod_topic_subscriber.start_link(client, @topic, _partitions = :all,
                                      consumer_config, __MODULE__, @table)
  end

  def init(@topic, @table) do
    :ets.new(@table, [:set, :protected, :named_table])
    {:ok, [], %{}}
  end

  def handle_message(_partition, msg, state) do
    key_bin = kafka_message(msg, :key)
    value_bin = kafka_message(msg, :value)
    {tag, key, value} = :kpro_consumer_group.decode(key_bin, value_bin)
    kf = fn(k) ->
      {:ok, v} = Keyword.fetch(key, k)
      v
    end
    case tag do
      :offset -> update_ets({kf.(:group_id), kf.(:topic), kf.(:partition)}, value)
      :group  -> update_ets(kf.(:group_id), value)
    end
    {:ok, :ack, state}
  end

  defp get_type(group_id) when is_binary(group_id) do
    :group
  end
  defp get_type({group_id, _topic, _partition}) when is_binary(group_id) do
    :offset
  end

  defp update_ets(key, _value = []) do
    :ets.delete(@table, key)
  end
  defp update_ets(key, value) do
    :ets.insert(@table, {key, value})
  end
end

