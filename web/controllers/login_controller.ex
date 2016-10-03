defmodule Kastlex.LoginController do
  import Comeonin.Bcrypt
  use Kastlex.Web, :controller

  def login(conn, %{"username" => name, "password" => password}) do
    case Kastlex.get_user(name) do
      false ->
        dummy_checkpw() # security ftw
        send_json(conn, 401, {:error, "invalid username or password"})
      user ->
        case checkpw(password, user[:password_hash]) do
          false ->
            send_json(conn, 401, {:error, "invalid username or password"})
          true ->
            {:ok, token, _} = Guardian.encode_and_sign(%{user: name})
            json(conn, %{token: token})
        end
    end
  end

end
