defmodule Kastlex.KastleController do

  require Logger

  use Kastlex.Web, :controller

  def create(conn, %{"topic" => topic, "partition" => partition} = params) do
    {partition, _} = Integer.parse(partition)
    key = Map.get(params, "key", "")
    {:ok, value, conn} = read_body(conn)
    do_create(conn, topic, partition, key, value)
  end

  def create(conn, %{"topic" => topic} = params) do
    partition = fn(_topic, cnt, _key, _value) -> {:ok, :crypto.rand_uniform(0, cnt)} end
    key = Map.get(params, "key", "")
    {:ok, value, conn} = read_body(conn)
    do_create(conn, topic, partition, key, value)
  end

  defp do_create(conn, topic, partition, key, value) do
    case :brod.produce_sync(:kastlex, topic, partition, key, value) do
      :ok ->
        send_resp(conn, 204, "")
      {:error, :UnknownTopicOrPartition} ->
        send_json(conn, 404, %{error: "unknown topic or partition"})
      {:error, {:producer_not_found, _topic}} ->
        send_json(conn, 404, %{error: "unknown topic"})
      {:error, {:producer_not_found, _topic, _partition}} ->
        send_json(conn, 404, %{error: "unknown partition"})
      {:error, reason} ->
        Logger.error "#{reason}"
        send_json(conn, 503, %{error: "service unavailable"})
    end
  end

end
