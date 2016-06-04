defmodule Kastlex.Router do
  use Kastlex.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Kastlex do
    pipe_through :api

    scope "/api/v1", as: :api_v1, alias: API.V1 do
      resources "/topics", TopicController, param: "topic", only: [:index, :show]
      resources "/brokers", BrokerController, only: [:index]
      resources "/offsets/:topic", OffsetsController, param: "partition", only: [:show]
      resources "/message/:topic", MessageController, param: "partition", only: [:create, :show]
    end
  end
end
