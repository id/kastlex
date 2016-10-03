defmodule Kastlex.Plug.EnsureAuthenticated do
  require Logger
  import Plug.Conn
  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    case Guardian.Plug.claims(conn) do
      {:ok, _claims} -> conn
      {:error, :no_session} -> conn
      {:error, reason} -> handle_error(conn, {:error, reason}, opts)
    end
  end

  defp handle_error(conn, reason, _opts) do
    Logger.error "#{inspect reason}"
    conn = conn |> assign(:guardian_failure, reason) |> halt
    params = Map.merge(conn.params, %{reason: reason})
    Kastlex.AuthErrorHandler.unauthenticated(conn, params)
  end
end

