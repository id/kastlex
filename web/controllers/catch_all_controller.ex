defmodule Kastlex.CatchAllController do

  use Kastlex.Web, :controller

  def favicon(conn, _params) do
    send_json(conn, 404, %{error: "Not found"})
  end

end
