# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :kastlex, Kastlex.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "2N8sGXA6wijnGpzmiEl3y6H2YCf7RbeBbi7xgE58txpm6AxDWS+A4TYrUY0jYYGV",
  render_errors: [accepts: ~w(json)],
  pubsub: [name: Kastlex.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time [$level] $metadata $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "Kastlex",
  ttl: { 30, :days },
  verify_issuer: true, # optional
  secret_key: "yCWR+HlWNjnBzh1UsGducT9Irq8zmAWxMbPUV+e3S70cPXeJRMz62y5xDtB3qCRL",
  serializer: Kastlex.GuardianSerializer,
  permissions: %{client: [:get_topic, :offsets, :fetch, :produce],
                 admin: [:list_topics, :list_brokers, :issue_token]}
