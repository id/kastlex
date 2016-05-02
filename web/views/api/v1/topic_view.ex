defmodule Kastlex.API.V1.TopicView do
  use Kastlex.Web, :view

  def render("index.json", %{topics: topics}) do
    topics
  end

  def render("show.json", %{topic: topic}) do
    topic
  end

end
