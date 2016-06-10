defmodule Kastlex.AuthErrorHandler do

  import Plug.Conn
  import Kastlex.Helper

  def unauthenticated(conn, _params) do
    send_json(conn, 401, %{error: "Unauthenticated"})
  end

  def unauthorized(conn, _params) do
    IO.inspect conn
    send_json(conn, 403, %{error: "Unauthorized"})
  end

  def already_authenticated(conn, _params) do
    conn |> halt
  end

end

