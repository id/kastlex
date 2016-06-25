defmodule Kastlex do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    endpoint = Application.fetch_env!(:kastlex, Kastlex.Endpoint)
    http = endpoint[:http]
    http = Keyword.put(http, :port, system_env("KASTLEX_HTTP_PORT", http[:port]))
    Application.put_env(:kastlex, Kastlex.Endpoint, Keyword.put(endpoint, :http, http))

    maybe_init_https(System.get_env("KASTLEX_USE_HTTPS"))
    maybe_set_secret_key(System.get_env("KASTLEX_SECRET_KEY_FILE"))
    maybe_set_jwk(System.get_env("KASTLEX_JWK_FILE"))
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

  defp maybe_init_https(nil), do: :ok
  defp maybe_init_https("true") do
    port = system_env("KASTLEX_HTTPS_PORT", 8093)
    keyfile = system_env("KASTLEX_KEYFILE", "/etc/kastlex/ssl/server.key")
    certfile = system_env("KASTLEX_CERTFILE", "/etc/kastlex/ssl/server.crt")
    cacertfile = system_env("KASTLEX_CACERTFILE", "/etc/kastlex/ssl/ca-cert.crt")
    config = [port: port, keyfile: keyfile, certfile: certfile, cacertfile: cacertfile]
    endpoint = Application.fetch_env!(:kastlex, Kastlex.Endpoint)
    Application.put_env(:kastlex, Kastlex.Endpoint, Keyword.put(endpoint, :https, config))
  end

  defp maybe_set_secret_key(nil), do: :ok
  defp maybe_set_secret_key(keyfile) do
    key = JOSE.JWK.from_file(keyfile)
    endpoint = Application.fetch_env!(:kastlex, Kastlex.Endpoint)
    Application.put_env(:kastlex, Kastlex.Endpoint, Keyword.put(endpoint, :secret_key_base, key))
  end

  defp maybe_set_jwk(nil), do: :ok
  defp maybe_set_jwk(keyfile) do
    key = JOSE.JWK.from_file(keyfile)
    guardian = Application.fetch_env!(:kastlex, Guardian)
    Application.put_env(:kastlex, Guardian, Keyword.put(guardian, :secret_key, key))
  end

  defp system_env(variable, default) do
    case System.get_env(variable) do
      nil -> default
      value -> value
    end
  end
end
