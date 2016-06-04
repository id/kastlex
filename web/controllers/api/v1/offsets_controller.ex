defmodule Kastlex.API.V1.OffsetsController do

  require Logger

  use Kastlex.Web, :controller

  def show(conn, %{"topic" => topic, "partition" => partition}) do
    {partition, _} = Integer.parse(partition)
    {:ok, pid} = :brod_client.get_leader_connection(:kastlex, topic, partition)
    {:ok, offsets} = :brod_utils.fetch_offsets(pid, topic, partition, :latest, 1)
    render(conn, "show.json", offsets: offsets)
  end

end
