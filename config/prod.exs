use Mix.Config

config :kastlex, Kastlex.Endpoint,
  http: [port: 8092],
  server: true,
  render_errors: [accepts: ~w(json), default_format: "json"],
  root: "."

config :logger, level: :info

import_config "prod.secret.exs"
