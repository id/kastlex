defmodule Kastlex.Helper do

  import Plug.Conn

  def send_json(conn, code, data) do
    encoder = get_json_encoder()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, encoder.encode_to_iodata!(data))
  end

  defp get_json_encoder do
    Application.get_env(:phoenix, :format_encoders) |>
      Keyword.get(:json, Poison)
  end

end
