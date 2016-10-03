use Mix.Config

config :kastlex, Kastlex.Endpoint,
  http: [port: 8092],
  server: true,
  root: "."

config :logger, level: :info

import_config "prod.secret.exs"
