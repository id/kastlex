defmodule Kastlex.API.V1.MessageController do

  require Logger

  use Kastlex.Web, :controller

  def show(conn, %{"topic" => topic, "partition" => partition} = params) do
    {partition, _} = Integer.parse(partition)
    {offset, _} = Integer.parse(Map.get(params, "offset"))
    max_wait_time = Integer.parse(Map.get(params, "max_wait_time", "1000"))
    min_bytes = Integer.parse(Map.get(params, "min_bytes", "1"))
    max_bytes = Integer.parse(Map.get(params, "max_bytes", "104857600")) # 100 kB

    request = :kpro.fetch_request(topic, partition, offset,
                                  max_wait_time, min_bytes, max_bytes)
    {:ok, pid} = :brod_client.get_leader_connection(:kastlex, topic, partition)
    {:ok, response} = :brod_sock.request_sync(pid, request, 10000)
    {:kpro_FetchResponse, [topicFetchData]} = response
    {:kpro_FetchResponseTopic, _, [partitionFetchData]} = topicFetchData
    {:kpro_FetchResponsePartition, _, errorCode, highWmOffset, size, messages} = partitionFetchData
    render(conn, "show.json", data: %{errorCode: errorCode,
                                      highWmOffset: highWmOffset,
                                      size: size,
                                      messages: messages_to_map(messages)})
  end

  defp messages_to_map(messages) do
    messages_to_map(messages, [])
  end

  defp messages_to_map([{:kpro_Message, offset, size, crc, _magicByte, _attributes, key, value} | tail], acc) do
    messages_to_map(tail, [%{offset: offset, size: size, crc: crc, key: key, value: value} | acc])
  end

  defp messages_to_map([], acc) do
    acc
  end

end
