defmodule Kastlex.MetadataCache do
  require Logger

  use GenServer

  @table __MODULE__
  @server __MODULE__
  @refresh :refresh

  @topics_path "/brokers/topics"

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
    :erlang.send_after(0, Kernel.self(), @refresh)
    {:ok, %{refresh_timeout_ms: Keyword.fetch!(env, :refresh_timeout_ms),
            zk: nil,
            zk_mref: nil,
            zk_cluster: Keyword.fetch!(env, :zk_cluster),
            zk_session_timeout: Keyword.fetch!(env, :zk_session_timeout),
            zk_chroot: Keyword.fetch!(env, :zk_chroot)}}
  end

  def handle_info(@refresh, state) do
    case connect_zk(state) do
      {:ok, state} ->
        case :erlzk.get_children(state.zk, @topics_path) do
          {:ok, topics} ->
            topics = Enum.map(topics, &read_topic_meta(state.zk, &1))
            :ets.insert(@table, {:ts, :erlang.system_time()})
            :ets.insert(@table, {:topics, topics})
            :erlang.send_after(state.refresh_timeout_ms, Kernel.self(), @refresh)
            {:noreply, state}
          {:error, reason} ->
            Logger.error "Skip refresh, zookeeper connection is down: #{reason}"
            {:noreply, state}
        end
      {:error, reason} ->
        Logger.error "Skip refresh, can't connect to zookeeper: #{reason}"
        {:noreply, state}
    end
  end

  def handle_info({:DOWN, zk_mref, :process, zk, _why},
        %{:zk_mref => zk_mref, :zk => zk} = state) do
    {:noreply, %{state | zk: nil, zk_mref: nil}}
  end

  def handle_info(msg, state) do
    Logger.error "Unexpected msg: #{msg}"
    {:noreply, state}
  end

  defp connect_zk(%{:zk => zk} = state) when Kernel.is_pid(zk), do: {:ok, state}
  defp connect_zk(state) do
    case :erlzk.connect(state.zk_cluster, state.zk_session_timeout, [chroot: state.zk_chroot]) do
      {:ok, zk} ->
        zk_mref = :erlang.monitor(:process, zk)
        {:ok, %{state | zk: zk, zk_mref: zk_mref}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_topic_meta(zk, topic) do
    topic = :erlang.list_to_binary(topic)
    path = Enum.join([@topics_path, topic], "/")
    {:ok, {json, _stat}} = :erlzk.get_data(zk, path)
    %{"partitions" => partitions} = Poison.decode!(json)
    partitions = Enum.map(partitions, &read_partition_meta(zk, topic, &1))
    %{topic: topic, partitions: partitions}
  end

  defp read_partition_meta(zk, topic, {partition, replicas}) do
    path = Enum.join([@topics_path, topic, "partitions", partition, "state"], "/")
    {:ok, {json, _stat}} = :erlzk.get_data(zk, path)
    %{"isr" => isr, "leader" => leader} = Poison.decode!(json)
    %{partition: partition, replicas: replicas, isr: isr, leader: leader}
  end

end
