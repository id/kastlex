defmodule Kastlex.API.V1.TopicController do

  require Logger

  use Kastlex.Web, :controller

  #plug :scrub_params, "topic" when action in [:show]

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


  # defp metadata_response_to_map({:kpro_MetadataResponse, brokers, topics}) do
  #   %{brokers: brokers_metadata_to_map(brokers), topics: topics_metadata_to_map(topics)}
  # end

  # defp brokers_metadata_to_map(brokers) do
  #   brokers_metadata_to_map(brokers, %{})
  # end

  # defp brokers_metadata_to_map([broker | tail], acc) do
  #   {:kpro_Broker, id, host, port} = broker
  #   brokers_metadata_to_map(tail, Map.put(acc, id, %{host: host, port: port}))
  # end

  # defp brokers_metadata_to_map([], acc) do
  #   acc
  # end

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
