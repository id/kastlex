use Mix.Config

config :kastlex, Kastlex.Endpoint,
  http: [port: 8092],
  server: true,
  root: "."

config :kastlex, Kastlex.Endpoint,
  https: [port: 8093,
          otp_app: :kastlex,
          keyfile: "/etc/kastlex/ssl/server.key",
          certfile: "/etc/kastlex/ssl/server.crt",
          cacertfile: "/etc/kastlex/ssl/ca-cert.crt"
         ],
  server: true,
  render_errors: [accepts: ~w(json), default_format: "json"],
  root: "."

config :logger, level: :info

import_config "prod.secret.exs"
