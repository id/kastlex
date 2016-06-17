defmodule Kastlex.API.V1.TopicController do

  require Logger

  use Kastlex.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Kastlex.AuthErrorHandler

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, admin: [:list_topics]}
    when action in [:index]

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, client: [:show_topic]}
    when action in [:show]

  plug Kastlex.Plug.Authorize when action in [:show]

  def index(conn, _params) do
    {:ok, _, topics} = Kastlex.MetadataCache.get_topics()
    topics = Enum.map(topics, fn(x) -> x.topic end)
    json(conn, topics)
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
