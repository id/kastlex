defmodule Kastlex.MessageControllerTest do
  use Kastlex.ConnCase

  @valid_attrs %{}
  @invalid_attrs %{}

  setup do
    {:ok, %{}}
  end

  test "show chosen resource", _params do
    topic = "kastlex"
    partition = 0
    offset = 1
    subj = %{user: "test", topics: topic}
    perms = %{client: [:fetch]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_message_path(conn, :show, topic, partition, offset))
    assert json_response(conn, 200)
  end

  test "does not show resource when permissions are wrong", _params do
    topic = "kastlex"
    partition = 0
    offset = 1
    subj = %{user: "test", topics: topic}
    perms = %{client: [:produce]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_message_path(conn, :show, topic, partition, offset))
    assert json_response(conn, 403)
  end

  test "does not show resource when it is not listed in subject", _params do
    topic = "kastlex"
    partition = 0
    offset = 1
    subj = %{user: "test", topics: "foo"}
    perms = %{client: [:fetch]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_message_path(conn, :show, topic, partition, offset))
    assert json_response(conn, 403)
  end

  test "returns 404 when resource does not exist", _params do
    topic = "foo"
    partition = 0
    offset = 1
    subj = %{user: "test", topics: topic}
    perms = %{client: [:fetch]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_message_path(conn, :show, topic, partition, offset))
    assert json_response(conn, 404)
  end

end
