defmodule Kastlex.API.V1.TopicController do

  require Logger

  use Kastlex.Web, :controller

  def index(conn, _params) do
    {:ok, {:kpro_MetadataResponse, _brokers, topics}} = :brod_client.get_metadata(:kastlex, :undefined)
    {:ok, msg} = Poison.encode(topics_metadata_to_map(topics))
    conn = resp(conn, 200, msg)
    send_resp(conn)
  end

  def show(conn, %{"topic" => name}) do
    {:ok, {:kpro_MetadataResponse, _brokers, topics}} = :brod_client.get_metadata(:kastlex, name)
    [topic] = topics_metadata_to_map(topics)
    {:ok, msg} = Poison.encode(topic)
    conn = resp(conn, 200, msg)
    send_resp(conn)
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
