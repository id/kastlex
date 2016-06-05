defmodule Kastlex.API.V1.OffsetController do

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
        send_resp(conn, 200, msg)
      {:error, :UnknownTopicOrPartition} ->
        {:ok, msg} = Poison.encode(%{error: "unknown topic or partition"})
        send_resp(conn, 404, msg)
      {:error, :LeaderNotAvailable} ->
        {:ok, msg} = Poison.encode(%{error: "unknown topic/partition or no leader for partition"})
        send_resp(conn, 404, msg)
      {:error, {:no_leader, _}} ->
        {:ok, msg} = Poison.encode(%{error: "unknown topic/partition or no leader for partition"})
        send_resp(conn, 404, msg)
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
