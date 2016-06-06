defmodule Kastlex.GuardianSerializer do
  @behaviour Guardian.Serializer

  def for_token(user), do: { :ok, "User:#{user}" }

  def from_token("User:" <> user), do: { :ok, user }
  def from_token(_), do: { :error, "Unknown resource type" }
end
