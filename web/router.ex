defmodule Kastlex.Router do
  use Kastlex.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  scope "/", Kastlex do
    pipe_through :api

    scope "/api/v1", as: :api_v1, alias: API.V1 do
      resources "/topics", TopicController, param: "topic", only: [:index, :show]
      resources "/brokers", BrokerController, only: [:index]
      resources "/offsets/:topic", OffsetController, param: "partition", only: [:show]
      resources "/messages/:topic/:partition", MessageController, param: "offset", only: [:create, :show]
    end
  end

end
