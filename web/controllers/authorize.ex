defmodule Kastlex.Plug.Authorize do

  require Logger
  import Plug.Conn

  def init(_opts) do
    %{}
  end

  def call(%Plug.Conn{params: %{"topic" => topic},
                      private: private} = conn, params) do
    %{:guardian_default_resource => %{topics: allowed_topics}} = private
    case "*" in allowed_topics or topic in allowed_topics do
      true  -> conn
      false -> handle_error(conn, params)
    end
  end

  defp handle_error(conn, params) do
    conn = conn |> halt
    Kastlex.AuthErrorHandler.unauthorized(conn, params)
  end

end
