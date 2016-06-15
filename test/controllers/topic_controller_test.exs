defmodule Kastlex.TopicControllerTest do
  use Kastlex.ConnCase

  @valid_attrs %{}
  @invalid_attrs %{}

  setup do
    {:ok, %{}}
  end

  test "lists all entries on index", _params do
    subj = %{user: "test", topics: "*"}
    perms = %{admin: [:list_topics]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_topic_path(conn, :index))
    assert is_list(json_response(conn, 200))
  end

  test "does not list all entries on index when permissions are not set", _params do
    subj = %{user: "test", topics: "*"}
    perms = %{client: [:show_topic]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_topic_path(conn, :index))
    assert json_response(conn, 403)
  end

  test "show chosen resource", _params do
    topic = "kastlex"
    subj = %{user: "test", topics: topic}
    perms = %{client: [:show_topic]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_topic_path(conn, :show, topic))
    assert json_response(conn, 200)["topic"] == topic
  end

  test "does not show resource when permissions are wrong", _params do
    topic = "kastlex"
    subj = %{user: "test", topics: topic}
    perms = %{admin: [:list_topics]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_topic_path(conn, :show, topic))
    assert json_response(conn, 403)
  end

  test "does not show resource when it is not listed in subject", _params do
    topic = "kastlex"
    subj = %{user: "test", topics: "foo"}
    perms = %{client: [:show_topic]}
    {:ok, token, _claims} = Guardian.encode_and_sign(subj, :token, perms: perms)
    conn = conn()
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", token)
      |> get(api_v1_topic_path(conn, :show, topic))
    assert json_response(conn, 403)
  end

end
