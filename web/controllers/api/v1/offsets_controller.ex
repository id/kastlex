defmodule Kastlex.API.V1.OffsetsController do

  require Logger

  use Kastlex.Web, :controller

  def show(conn, %{"topic" => topic, "partition" => partition}) do
    endpoints = Application.get_env(:kastlex, :kafka_endpoints)
    {partition, _} = Integer.parse(partition)
    {:ok, offsets} = :brod.get_offsets(endpoints, topic, partition)
    render(conn, "show.json", offsets: offsets)
  end

end
