defmodule Kastlex.API.V1.OffsetsView do
  use Kastlex.Web, :view

  def render("show.json", %{offsets: offsets}) do
    offsets
  end

end
