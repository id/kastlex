defmodule Kastlex.API.V1.ConsumerController do

  require Logger

  use Kastlex.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Kastlex.AuthErrorHandler

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, admin: [:list_consumers]}
    when action in [:list_groups]

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, client: [:show_consumer]}
    when action in [:show_group, :list_group_topics, :show_group_topic]

  def list_groups(conn, _params) do
    groups = Kastlex.CgStatusCollector.get_group_ids()
    json(conn, groups)
  end

  def show_group(conn, %{"group_id" => group_id}) do
    case Kastlex.CgStatusCollector.get_group(group_id) do
      {:ok, group} -> json(conn, group)
      false -> send_json(conn, 404, %{error: "unknown group"})
    end
  end

  def list_group_topics(conn, %{"group_id" => group_id}) do
    topics = Kastlex.CgStatusCollector.get_group_topics(group_id)
    json(conn, topics)
  end

  def show_group_topic(conn, %{"group_id" => group_id, "topic" => topic_name}) do
    topic = Kastlex.CgStatusCollector.get_group_topic(group_id, topic_name)
    json(conn, topic)
  end

end
