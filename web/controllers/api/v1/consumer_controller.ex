defmodule Kastlex.API.V1.ConsumerController do

  require Logger

  use Kastlex.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Kastlex.AuthErrorHandler

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, admin: [:list_consumers]}
    when action in [:index]

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, client: [:show_consumer]}
    when action in [:show]

  def index(conn, _params) do
    groups = Kastlex.CgStatusCollector.get_group_ids()
    json(conn, groups)
  end

  def show(conn, %{"group_id" => group_id}) do
    case Kastlex.CgStatusCollector.get_group(group_id) do
      {:ok, group} -> json(conn, group)
      false -> send_json(conn, 404, %{error: "unknown group"})
    end
  end

end
