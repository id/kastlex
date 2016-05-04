defmodule Kastlex.API.V1.TopicController do

  require Logger

  use Kastlex.Web, :controller

  def index(conn, _params) do
    endpoints = Application.get_env(:kastlex, :kafka_endpoints)
    {:ok, {:kpro_MetadataResponse, _brokers, topics}} = :brod.get_metadata(endpoints)
    render(conn, "index.json", topics: topics_metadata_to_map(topics))
  end

  def show(conn, %{"topic" => name}) do
    endpoints = Application.get_env(:kastlex, :kafka_endpoints)
    {:ok, {:kpro_MetadataResponse, _brokers, topics}} = :brod.get_metadata(endpoints, [name])
    [topic] = topics_metadata_to_map(topics)
    render(conn, "show.json", topic: topic)
  end

  defp topics_metadata_to_map(topics) do
    topics_metadata_to_map(topics, [])
  end

  defp topics_metadata_to_map([{:kpro_TopicMetadata, _, topic, partitions} | tail], acc) do
    topics_metadata_to_map(tail, [%{topic: topic, partitions: partition_metadata_to_map(partitions)} | acc])
  end

  defp topics_metadata_to_map([], acc) do
    acc
  end

  defp partition_metadata_to_map(partitions) do
    partition_metadata_to_map(partitions, [])
  end

  defp partition_metadata_to_map([p | tail], acc) do
    {:kpro_PartitionMetadata, _, partition, leader, replicas, isr} = p
    map = %{partition: partition, leader: leader, replicas: replicas, isr: isr}
    partition_metadata_to_map(tail, [map | acc])
  end

  defp partition_metadata_to_map([], acc) do
    acc
  end
end
