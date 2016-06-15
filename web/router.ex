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
      get  "/topics", TopicController, :index
      get  "/topics/:topic", TopicController, :show
      get  "/brokers", BrokerController, :index
      get  "/brokers/:broker", BrokerController, :show
      get  "/offsets/:topic/:partition", OffsetController, :show
      post "/messages/:topic/:partition", MessageController, :create
      get  "/messages/:topic/:partition/:offset", MessageController, :show
      post "/tokens", TokenController, :create
      get  "/urp", UrpController, :index
      get  "/urp/:topic", UrpController, :show
    end
  end

end
