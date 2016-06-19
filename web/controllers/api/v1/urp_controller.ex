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
    {:ok, topics} = Kastlex.MetadataCache.get_topics()
    urp = List.foldl(topics, [],
                     fn (t, acc) ->
                       urp = get_urp(t.partitions)
                       case urp do
                         []    -> acc
                         [_|_] ->
                           [%{topic: t.topic, urp: urp} | acc]
                       end
                     end)
    case urp do
      []    -> send_resp(conn, 204, "")
      [_|_] -> json(conn, urp)
    end
  end

  def show(conn, %{"topic" => name}) do
    {:ok, topics} = Kastlex.MetadataCache.get_topics()
    case Enum.find(topics, nil, fn(x) -> x.topic == name end) do
      nil ->
        send_json(conn, 404, %{error: "unknown topic"})
      topic ->
        urp = get_urp(topic.partitions)
        case urp do
          []    -> send_resp(conn, 204, "")
          [_|_] -> json(conn, %{topic: topic.topic, urp: urp})
        end
    end
  end

  defp get_urp(partitions), do: get_urp(partitions, [])

  defp get_urp([], acc), do: acc
  defp get_urp([p | tail], acc) do
    case p.replicas != p.isr do
      true -> [p | acc]
      false -> acc
    end
  end

end
