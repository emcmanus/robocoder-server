defmodule RobocoderWeb.Router do
  use RobocoderWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # No CSRF protection
  pipeline :unsafe_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
  end

  scope "/", RobocoderWeb do
    pipe_through :browser

    get "/auth/github", AccountsController, :github_auth
    get "/auth/github/callback", AccountsController, :github_callback

    post "/create-stripe-session", PageController, :create_stripe_session

    get "/success", PageController, :stripe_success
    get "/cancel", PageController, :stripe_cancel

    get "/logout", SessionController, :delete
    get "/error", ErrorController, :error

    get "/", PageController, :index
  end

  scope "/", RobocoderWeb do
    pipe_through :unsafe_api
    post "/validate-license-key", AccountsController, :validate_license_key
    post "/stripe-webhook", StripeController, :webhook

    post "/events/mail", PageController, :stripe_success # fuck you gmail
  end
end
