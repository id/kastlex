defmodule Kastlex.CgStatusCollector do
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :kafka_message,
             extract(:kafka_message, from_lib: "brod/include/brod.hrl")

  @behaviour :brod_topic_subscriber

  @table_groups  :consumer_groups
  @table_offsets :consumer_offsets
  @topic "__consumer_offsets"
  @server __MODULE__

  def get_group_ids() do
    :ets.select(@table_groups, [{{:"$1", :_}, [], [:"$1"]}])
  end

  def get_group(group_id) do
    case :ets.lookup(@table_groups, group_id) do
      [] -> false
      [{_, group}] -> {:ok, group}
    end
  end

  def get_offsets() do
    # get just values
    :ets.select(@table_offsets, [{{:_, :"$1"}, [], [:"$1"]}])
  end

  def start_link(options) do
    client = options.brod_client_id
    consumer_config = [{:begin_offset, :earliest}]
    ## start a topic subscriber which will spawn one consumer process
    ## for each partition, and subscribe to all partition consumers
    :brod_topic_subscriber.start_link(client, @topic, _partitions = :all,
                                      consumer_config, __MODULE__, nil)
  end

  def init(@topic, _) do
    :ets.new(@table_groups, [:set, :protected, :named_table])
    :ets.new(@table_offsets, [:set, :protected, :named_table])
    {:ok, [], %{}}
  end

  def handle_message(_partition, msg, state) do
    key_bin = kafka_message(msg, :key)
    value_bin = kafka_message(msg, :value)
    {tag, key, value} = :kpro_consumer_group.decode(true, key_bin, value_bin)
    case tag do
      :offset -> update_ets(@table_offsets, {key[:group_id], key[:topic], key[:partition]},
                            :maps.merge(key, value))
      :group  -> update_ets(@table_groups, key[:group_id], :maps.merge(key, value))
    end
    {:ok, :ack, state}
  end

  #defp update_ets(table, key, _value = %{}), do: :ets.delete(table, key)
  defp update_ets(table, key, value),        do: :ets.insert(table, {key, value})
end

