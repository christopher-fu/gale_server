defmodule GaleServer.Router do
  use GaleServer.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  scope "/", GaleServer do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", GaleServer do
    pipe_through :api

    # Unauthorized routes
    post "/login", UnauthUserController, :log_in
    post "/user", UnauthUserController, :make_user

    # Authorized routes

    # :username shows up as a key-value pair in the params map of
    # UserController.get_user
    get "/user/:username", UserController, :get_user
    get "/friendreq", UserController, :get_friend_reqs
    get "/friendreq/:freq_id", UserController, :get_friend_req
    put "/friendreq/:freq_id", UserController, :update_friend_req
    post "/friendreq", UserController, :send_friend_req

    get "/friend", UserController, :get_friends
  end
end
