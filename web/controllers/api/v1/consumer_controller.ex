defmodule Kastlex.API.V1.ConsumerController do

  require Logger

  use Kastlex.Web, :controller

  plug Kastlex.Plug.EnsurePermissions

  def list_groups(conn, _params) do
    groups = Kastlex.CgCache.get_groups()
    json(conn, groups)
  end

  def show_group(conn, %{"group_id" => group_id}) do
    case Kastlex.CgCache.get_group(group_id) do
      false -> send_json(conn, 404, %{error: "unknown group"})
      group -> json(conn, group)
    end
  end

end
