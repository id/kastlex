defmodule Kastlex.GuardianSerializer do
  require Logger
  @behaviour Guardian.Serializer

  def for_token(%{user: user}), do: {:ok, "user:#{user}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("user:" <> name) do
    case Kastlex.get_user(name) do
      false ->
        Logger.error "Unknown user #{inspect name}"
        {:error, "Invalid token"}
      user ->
        {:ok, user}
    end
  end
  def from_token(other) do
    Logger.error "Invalid token #{inspect other}"
    {:error, "Invalid token"}
  end

end
