defmodule Kastlex.API.V1.BrokerView do
  use Kastlex.Web, :view

  def render("index.json", %{brokers: brokers}) do
    brokers
  end

end
