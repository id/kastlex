defmodule Kastlex.BrokerControllerTest do
  use Kastlex.ConnCase

  setup do
    {:ok, %{}}
  end

  test "lists all entries on index", _params do
    subj = %{user: "test", topics: "*"}
    perms = %{admin: [:list_brokers]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_broker_path(conn, :index))
    assert is_list(json_response(conn, 200))
  end

  test "does not list all entries on index when permissions are not set", _params do
    subj = %{user: "test", topics: "*"}
    perms = %{client: [:show_topic]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_broker_path(conn, :index))
    assert json_response(conn, 403)
  end

end
