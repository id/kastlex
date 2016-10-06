defmodule Kastlex.API.V1.MessageController do

  require Logger

  use Kastlex.Web, :controller

  plug Kastlex.Plug.EnsurePermissions

  # TODO: partitioner
  def produce(conn, %{"topic" => topic, "partition" => partition} = params) do
    {partition, _} = Integer.parse(partition)
    key = Map.get(params, "key", "")
    {:ok, value, conn} = read_body(conn)
    case :brod.produce_sync(:kastlex, topic, partition, key, value) do
      :ok ->
        send_resp(conn, 204, "")
      {:error, :UnknownTopicOrPartition} ->
        send_json(conn, 404, %{error: "Unknown topic or partition"})
      {:error, {:producer_not_found, _topic}} ->
        send_json(conn, 404, %{error: "Unknown topic"})
      {:error, {:producer_not_found, _topic, _partition}} ->
        send_json(conn, 404, %{error: "Unknown partition"})
      {:error, reason} ->
        Logger.error "#{reason}"
        send_json(conn, 503, %{error: "Service unavailable"})
    end
  end

  def fetch(conn, %{"topic" => topic, "partition" => partition, "offset" => offset} = params) do
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
        resp = %{errorCode: errorCode,
                 highWmOffset: highWmOffset,
                 size: size,
                 messages: messages_to_map(messages)}
        json(conn, resp)
      {:error, :UnknownTopicOrPartition} ->
        send_json(conn, 404, %{error: "Unknown topic or partition"})
      {:error, :LeaderNotAvailable} ->
        send_json(conn, 404, %{error: "Leader not available"})
    end
  end

  defp messages_to_map(messages), do: messages_to_map(messages, [])

  defp messages_to_map([], acc), do: acc
  defp messages_to_map([:incomplete_message | tail], acc), do: messages_to_map(tail, acc)
  defp messages_to_map([msg | tail], acc) do
    {:kpro_Message, offset, size, crc, _magicByte, _attributes, key, value} = msg
    key = undefined_to_null(key)
    value = undefined_to_null(value)
    messages_to_map(tail, [%{offset: offset, size: size, crc: crc, key: key, value: value} | acc])
  end

  defp undefined_to_null(:undefined), do: nil
  defp undefined_to_null(x),          do: x

end
