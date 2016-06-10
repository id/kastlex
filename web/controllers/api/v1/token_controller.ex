defmodule Kastlex.API.V1.TokenController do

  require Logger

  use Kastlex.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Kastlex.AuthErrorHandler
  plug Guardian.Plug.EnsurePermissions, handler: Kastlex.AuthErrorHandler, admin: [:issue_token]

  def create(conn, _params) do
    {:ok, body, conn} = read_body(conn)
    data = Poison.decode!(body)
    user = data["user"]
    topics = data["topics"]
    perms = data["perms"]
    perms = Map.new(Enum.map(Map.to_list(perms),
                             fn({scope, set}) ->
                               {:erlang.binary_to_atom(scope, :utf8),
                                Enum.map(set,
                                         fn(x) -> :erlang.binary_to_atom(x, :utf8) end)
                               }
                             end))
    subject = %{user: user, topics: topics}
    {:ok, token, _} = Guardian.encode_and_sign(subject, :token, perms: perms)
    json(conn, %{token: token})
  end
end
