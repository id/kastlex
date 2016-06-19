defmodule Kastlex.API.V1.BrokerController do

  require Logger

  use Kastlex.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Kastlex.AuthErrorHandler

  plug Guardian.Plug.EnsurePermissions, handler: Kastlex.AuthErrorHandler, admin: [:list_brokers]

  def index(conn, _params) do
    {:ok, brokers} = Kastlex.MetadataCache.get_brokers()
    json(conn, brokers)
  end

  def show(conn, %{"broker" => id}) do
    {:ok, brokers} = Kastlex.MetadataCache.get_brokers()
    {id, _} = Integer.parse(id)
    case Enum.find(brokers, nil, fn(x) -> x.id == id end) do
      nil ->
        send_json(conn, 404, %{error: "unknown broker id"})
      broker ->
        json(conn, broker)
    end
  end

end
