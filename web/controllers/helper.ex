defmodule Kastlex.Helper do

  import Plug.Conn

  def send_json(conn, code, data) do
    encoder = get_json_encoder()
    conn
    |> ensure_resp_content_type("application/json")
    |> send_resp(code, encoder.encode_to_iodata!(data))
  end

  defp get_json_encoder do
    Application.get_env(:phoenix, :format_encoders)
    |> Keyword.get(:json, Poison)
  end

  defp ensure_resp_content_type(%{resp_headers: resp_headers} = conn, content_type) do
    if List.keyfind(resp_headers, "content-type", 0) do
      conn
    else
      content_type = content_type <> "; charset=utf-8"
      %{conn | resp_headers: [{"content-type", content_type}|resp_headers]}
    end
  end
end
