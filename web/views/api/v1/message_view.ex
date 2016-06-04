defmodule Kastlex.API.V1.MessageView do
  use Kastlex.Web, :view

  def render("show.json", %{data: data}) do
    data
  end

end
