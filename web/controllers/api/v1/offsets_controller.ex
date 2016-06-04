defmodule Kastlex.API.V1.OffsetsController do

  require Logger

  use Kastlex.Web, :controller

  def show(conn, %{"topic" => topic, "partition" => partition} = params) do
    {partition, _} = Integer.parse(partition)
    at = parse_at(Map.get(params, "at", "latest"))
    {maxOffsets, _} = Integer.parse(Map.get(params, "maxOffsets", "1"))
    case :brod_client.get_leader_connection(:kastlex, topic, partition) do
      {:ok, pid} ->
        {:ok, offsets} = :brod_utils.fetch_offsets(pid, topic, partition, at, maxOffsets)
        {:ok, msg} = Poison.encode(offsets)
        conn = resp(conn, 200, msg)
        send_resp(conn)
      {:error, :UnknownTopicOrPartition} ->
        {:ok, msg} = Poison.encode(%{error: "unknown topic or partition"})
        conn = resp(conn, 404, msg)
        send_resp(conn)
    end
  end

  defp parse_at("earliest") do
    -2
  end

  defp parse_at("latest") do
    -1
  end

  defp parse_at(n) do
    {at, _} = Integer.parse(n)
    at
  end

end
