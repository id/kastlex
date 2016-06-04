defmodule Kastlex.API.V1.BrokerController do

  require Logger

  use Kastlex.Web, :controller

  def index(conn, _params) do
    {:ok, {:kpro_MetadataResponse, brokers, _topics}} = :brod_client.get_metadata(:kastlex, :undefined)
    render(conn, "index.json", brokers: brokers_metadata_to_map(brokers))
  end

  defp brokers_metadata_to_map(brokers) do
    brokers_metadata_to_map(brokers, [])
  end

  defp brokers_metadata_to_map([broker | tail], acc) do
    {:kpro_Broker, id, host, port} = broker
    brokers_metadata_to_map(tail, [%{id: id, host: host, port: port} | acc])
  end

  defp brokers_metadata_to_map([], acc) do
    acc
  end

end
