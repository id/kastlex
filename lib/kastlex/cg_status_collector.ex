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
    ms = [{{:"$1", :_}, [], [:"$1"]}]
    :ets.select(@table_groups, ms)
  end

  def get_group(group_id) do
    ets_lookup(@table_groups, group_id, false)
  end

  def get_group_topics(group) do
    ms = [{{{group, :"$1", :_}, :_}, [], [:"$1"]}]
    :ets.select(@table_offsets, ms)
  end

  def get_group_topic(group, topic) do
    ms = [{{{group, topic, :_}, :"$1"}, [], [:"$1"]}]
    :ets.select(@table_offsets, ms)
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
    {tag, data} = :kpro_consumer_group.to_maps(:kpro_consumer_group.decode(key_bin, value_bin))
    case tag do
      :offset ->
        data =
          maybe_fix_epoch(data, :commit_time) |>
          maybe_fix_epoch(:expire_time)
        :ets.insert(@table_offsets, {{data.group_id, data.topic, data.partition}, data})
      :group ->
        :ets.insert(@table_groups, {data.group_id, data})
    end
    {:ok, :ack, state}
  end

  defp ets_lookup(table, key, default) do
    case :ets.lookup(table, key) do
      [] -> {:ok, default}
      [{_, value}] -> {:ok, value}
    end
  end

  defp maybe_fix_epoch(map, key) do
    case Map.has_key?(map, key) do
      true -> Map.update!(map, key, &epoch_to_str/1)
      false -> map
    end
  end

  defp epoch_to_str(epoch) do
    {:ok, dt} = DateTime.from_unix(epoch, :milliseconds)
    DateTime.to_string(dt)
  end
end

