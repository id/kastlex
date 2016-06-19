defmodule Kastlex do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    kafka_endpoints = parse_endpoints(System.get_env("KASTLEX_KAFKA_CLUSTER"), [{'localhost', 9092}])
    zk_cluster = parse_endpoints(System.get_env("KASTLEX_ZOOKEEPER_CLUSTER"), [{'localhost', 2181}])

    brod_client_config = [{:allow_topic_auto_creation, false},
                          {:auto_start_producers, true}]
    :ok = :brod.start_client(kafka_endpoints, :kastlex, brod_client_config)

    children = [
      # Start the endpoint when the application starts
      supervisor(Kastlex.Endpoint, []),
      # Start the metadata cache worker
      worker(Kastlex.MetadataCache, [%{zk_cluster: zk_cluster}]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kastlex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Kastlex.Endpoint.config_change(changed, removed)
    :ok
  end

  defp parse_endpoints(nil, default), do: default
  defp parse_endpoints(endpoints, _default) do
    endpoints
      |> String.split(",")
      |> Enum.map(&String.split(&1, ":"))
      |> Enum.map(fn([host, port]) -> {:erlang.binary_to_list(host), :erlang.binary_to_integer(port)} end)
  end
end
