defmodule Kastlex.Plug.RequestMeta do

  require Logger
  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    Logger.metadata(remote_ip: :inet.ntoa(conn.remote_ip))
    conn
  end

end
