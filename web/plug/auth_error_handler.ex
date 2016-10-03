defmodule Kastlex.AuthErrorHandler do

  use Kastlex.Web, :controller

  @callback unauthenticated(Plug.t, Map.t) :: Plug.t
  @callback unauthorized(Plug.t, Map.t) :: Plug.t
  @callback already_authenticated(Plug.t, Map.t) :: Plug.t

  def unauthenticated(conn, _params) do
    send_json(conn, 401, %{error: "Unauthenticated"})
  end

  def unauthorized(conn, _params) do
    send_json(conn, 403, %{error: "Unauthorized"})
  end

  def already_authenticated(conn, _params) do
    conn |> halt
  end

end

