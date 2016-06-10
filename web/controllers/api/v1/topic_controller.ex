defmodule Kastlex.API.V1.TopicController do

  require Logger

  use Kastlex.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: Kastlex.AuthErrorHandler

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, admin: [:list_topics]}
    when action in [:index]

  plug Guardian.Plug.EnsurePermissions,
    %{handler: Kastlex.AuthErrorHandler, client: [:get_topic]}
    when action in [:show]

  plug Kastlex.Plug.Authorize when action in [:show]

  def index(conn, _params) do
    {:ok, {:kpro_MetadataResponse, _brokers, topics}} = :brod_client.get_metadata(:kastlex, :undefined)
    json(conn, topics_metadata_to_list(topics))
  end

  def show(conn, %{"topic" => name}) do
    {:ok, {:kpro_MetadataResponse, _brokers, topics}} = :brod_client.get_metadata(:kastlex, name)
    [topic] = topics_metadata_to_map(topics)
    json(conn, topic)
  end

  defp topics_metadata_to_list(topics), do: topics_metadata_to_list(topics, [])

  defp topics_metadata_to_list([], acc), do: acc
  defp topics_metadata_to_list([{:kpro_TopicMetadata, _, topic, _partitions} | tail], acc) do
    topics_metadata_to_list(tail, [topic | acc])
  end

  defp topics_metadata_to_map(topics), do: topics_metadata_to_map(topics, [])

  defp topics_metadata_to_map([], acc), do: acc
  defp topics_metadata_to_map([{:kpro_TopicMetadata, _, topic, partitions} | tail], acc) do
    topics_metadata_to_map(tail, [%{topic: topic, partitions: partition_metadata_to_map(partitions)} | acc])
  end

  defp partition_metadata_to_map(partitions) do
    partition_metadata_to_map(partitions, [])
  end

  defp partition_metadata_to_map([], acc), do: acc
  defp partition_metadata_to_map([p | tail], acc) do
    {:kpro_PartitionMetadata, _, partition, leader, replicas, isr} = p
    map = %{partition: partition, leader: leader, replicas: replicas, isr: isr}
    partition_metadata_to_map(tail, [map | acc])
  end
end
