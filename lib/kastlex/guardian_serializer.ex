defmodule Kastlex.GuardianSerializer do
  @behaviour Guardian.Serializer

  def for_token(%{user: user, topics: topics}), do: { :ok, "user: #{user}, topics: #{topics}" }
  def for_token(%{user: user}), do: { :ok, "user: #{user}, topics: *" }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token(subject) do
    # "user: foo, topics: [a,b,c]")
    case Regex.named_captures(~r/user: (?<user>.+), topics: (?<topics>.+)/, subject) do
      nil -> {:error, "Unknown resource type" }
      map ->
        user = map["user"]
        topics = String.split(map["topics"], ",")
        {:ok, %{user: user, topics: topics}}
    end
  end
end
