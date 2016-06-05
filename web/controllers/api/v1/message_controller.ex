
defmodule Kastlex.API.V1.MessageController do

  require Logger

  use Kastlex.Web, :controller

  def create(conn, %{"topic" => topic, "partition" => partition} = params) do
    {partition, _} = Integer.parse(partition)
    key = Map.get(params, "key", "")
    {:ok, value, conn} = read_body(conn)
    case :brod.produce_sync(:kastlex, topic, partition, key, value) do
      :ok ->
        send_resp(conn, 201, "")
      {:error, :UnknownTopicOrPartition} ->
        {:ok, msg} = Poison.encode(%{error: "unknown topic or partition"})
        send_resp(conn, 404, msg)
      {:error, {:producer_not_found, _topic}} ->
        {:ok, msg} = Poison.encode(%{error: "unknown topic"})
        send_resp(conn, 404, msg)
      {:error, {:producer_not_found, _topic, _partition}} ->
        {:ok, msg} = Poison.encode(%{error: "unknown partition"})
        send_resp(conn, 404, msg)
      {:error, reason} ->
        requestId = get_resp_header(conn, "x-request-id")
        Logger.error "#{reason}"
        {:ok, msg} = Poison.encode(%{error: "service unavailable"})
        send_resp(conn, 503, msg)
    end
  end

  def show(conn, %{"topic" => topic, "partition" => partition, "offset" => offset} = params) do
    {partition, _} = Integer.parse(partition)
    {offset, _} = Integer.parse(offset)
    {max_wait_time, _} = Integer.parse(Map.get(params, "max_wait_time", "1000"))
    {min_bytes, _} = Integer.parse(Map.get(params, "min_bytes", "1"))
    {max_bytes, _} = Integer.parse(Map.get(params, "max_bytes", "104857600")) # 100 kB

    request = :kpro.fetch_request(topic, partition, offset,
                                  max_wait_time, min_bytes, max_bytes)
    case :brod_client.get_leader_connection(:kastlex, topic, partition) do
      {:ok, pid} ->
        {:ok, response} = :brod_sock.request_sync(pid, request, 10000)
        {:kpro_FetchResponse, [topicFetchData]} = response
        {:kpro_FetchResponseTopic, _, [partitionFetchData]} = topicFetchData
        {:kpro_FetchResponsePartition, _, errorCode, highWmOffset, size, messages} = partitionFetchData
        {:ok, msg} = Poison.encode(%{errorCode: errorCode,
                                     highWmOffset: highWmOffset,
                                     size: size,
                                     messages: messages_to_map(messages)})
        send_resp(conn, 200, msg)
      {:error, :UnknownTopicOrPartition} ->
        {:ok, msg} = Poison.encode(%{error: "unknown topic or partition"})
        send_resp(conn, 404, msg)
    end
  end

  defp messages_to_map(messages) do
    messages_to_map(messages, [])
  end

  defp messages_to_map([{:kpro_Message, offset, size, crc, _magicByte, _attributes, key, value} | tail], acc) do
    key = undefined_to_null(key)
    value = undefined_to_null(value)
    messages_to_map(tail, [%{offset: offset, size: size, crc: crc, key: key, value: value} | acc])
  end

  defp messages_to_map([:incomplete_message | tail], acc) do
    messages_to_map(tail, acc)
  end

  defp messages_to_map([], acc) do
    acc
  end

  defp undefined_to_null(:undefined) do
    :null
  end

  defp undefined_to_null(x) do
    x
  end

end
