defmodule Kastlex.API.V1.BrokerController do

  require Logger

  use Kastlex.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Kastlex.AuthErrorHandler
  plug Guardian.Plug.EnsurePermissions, handler: Kastlex.AuthErrorHandler, admin: [:list_brokers]

  def index(conn, _params) do
    {:ok, _, brokers} = Kastlex.MetadataCache.get_brokers()
    json(conn, brokers)
  end


end
