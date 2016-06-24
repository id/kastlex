defmodule Kastlex.Plug.Authorize do

  require Logger
  import Plug.Conn
  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{params: %{"topic" => topic},
                      private: private} = conn, _opts) do
    %{:guardian_default_resource => %{topics: allowed_topics}} = private
    case "*" in allowed_topics or topic in allowed_topics do
      true  -> conn
      false -> handle_error(conn)
    end
  end

  defp handle_error(conn) do
    conn = conn |> halt
    Kastlex.AuthErrorHandler.unauthorized(conn, %{})
  end

end
