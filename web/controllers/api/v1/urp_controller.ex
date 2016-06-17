defmodule Kastlex.API.V1.UrpController do

  require Logger

  use Kastlex.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Kastlex.AuthErrorHandler

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, admin: [:list_urps]}
    when action in [:index]

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, client: [:show_urp]}
    when action in [:show]

  plug Kastlex.Plug.Authorize when action in [:show]

  def index(conn, _params) do
    {:ok, _, topics} = Kastlex.MetadataCache.get_topics()
    urp = List.foldl(topics, [],
                     fn (t, acc) ->
                       partitions = List.foldl(t.partitions,
                                               [],
                                               fn(p, acc) ->
                                                 case p.error_code == :ReplicaNotAvailable do
                                                   true -> [p | acc]
                                                   false -> acc
                                                 end
                                               end)
                       case partitions do
                         []    -> acc
                         [_|_] ->
                           [%{t | :partitions => partitions} | acc]
                       end
                     end)
    case urp do
      []    -> send_resp(conn, 204, "")
      [_|_] -> json(conn, urp)
    end
  end

  def show(conn, %{"topic" => name}) do
    {:ok, _, topics} = Kastlex.MetadataCache.get_topics()
    case Enum.find(topics, nil, fn(x) -> x.topic == name end) do
      nil ->
        send_json(conn, 404, %{error: "unknown topic"})
      topic ->
        json(conn, topic)
    end
  end

end
