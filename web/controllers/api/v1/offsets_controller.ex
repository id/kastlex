defmodule Kastlex.API.V1.OffsetsController do

  require Logger

  use Kastlex.Web, :controller

  def show(conn, %{"topic" => topic, "partition" => partition} = params) do
    {partition, _} = Integer.parse(partition)
    {at, _} = Integer.parse(Map.get(params, "at", "-1"))
    {maxOffsets, _} = Integer.parse(Map.get(params, "maxOffsets", "1"))
    {:ok, pid} = :brod_client.get_leader_connection(:kastlex, topic, partition)
    {:ok, offsets} = :brod_utils.fetch_offsets(pid, topic, partition, at, maxOffsets)
    render(conn, "show.json", offsets: offsets)
  end

end
