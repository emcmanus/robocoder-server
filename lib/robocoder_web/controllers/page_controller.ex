defmodule RobocoderWeb.PageController do
  use RobocoderWeb, :controller
  alias Robocoder.Accounts

  def index(conn, _params) do
    user_id = get_session(conn, :user_id)

    if user_id do
      user = Accounts.get_user(user_id)

      token = if user.subscription_status != "active" do
        nil
      else
        user.api_token
      end

      if user.subscription_status == "active" do
        render(conn, "home.html", layout: false, api_token: token, stripe_customer_id: user.stripe_customer_id, stripe_subscription_id: user.stripe_subscription_id, subscription_status: user.subscription_status, manage_subscription_url: Application.get_env(:robocoder, :stripe)[:manage_url])
      else
        render(conn, "subscribe.html", layout: false )
      end
    else
      render(conn, "login.html", layout: false)
    end
  end

  def stripe_success(conn, _params) do
    render(conn, "success.html")
  end

  def stripe_cancel(conn, _params) do
    render(conn, "cancel.html")
  end

  def create_stripe_session(conn, _params) do
    user_id = get_session(conn, :user_id)
    user = Accounts.get_user(user_id)

    if user do
      # Define the success and cancel URLs
      success_url = Application.get_env(:robocoder, :stripe)[:success_url]
      cancel_url = Application.get_env(:robocoder, :stripe)[:cancel_url]

      # Prepare the parameters for the Stripe API
      stripe_params = %{
        payment_method_types: ["card"],
        line_items: [
          %{
            price: Application.get_env(:robocoder, :stripe)[:price_id],
            quantity: 1
          }
        ],
        mode: "subscription",
        success_url: success_url,
        cancel_url: cancel_url,
        customer_email: user.email,
        metadata: %{
          user_id: user.id
        }
      }

      # Check if the user has an existing stripe_customer_id and add it to the params
      stripe_params = if user.stripe_customer_id do
        stripe_params
        |> Map.drop([:customer_email])
        |> Map.drop([:metadata])
        |> Map.put(:customer, user.stripe_customer_id)
      else
        stripe_params
      end

      try do
        { :ok, session } = Stripe.Checkout.Session.create(stripe_params)
        if !user.stripe_customer_id do
          Accounts.update_stripe_customer_id(user, session.customer)
        end
        json(conn, %{session_id: session.id})
      rescue
        e in Stripe.Error ->
          # Log the Stripe error details
          IO.inspect(e, label: "Stripe Error")
          conn
          |> put_flash(:error, "There was an error creating the Stripe session: #{e.message}")
          |> redirect(to: '/')
        e in _ ->
          # Log unexpected errors
          IO.inspect(e, label: "Unexpected Error")
          conn
          |> put_flash(:error, "An unexpected error occurred.")
          |> redirect(to: '/')
      end
    else
      # Handle case where user is not found or not logged in
      conn
      |> put_flash(:error, "You must be logged in to subscribe.")
      |> redirect(to: '/')
    end
  end

end
