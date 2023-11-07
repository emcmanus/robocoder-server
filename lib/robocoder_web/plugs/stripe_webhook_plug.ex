defmodule RobocoderWeb.StripeWebhookPlug do
  @behaviour Plug

  import Plug.Conn

  def init(config), do: config

  def call(%{request_path: "/stripe-webhook"} = conn, _) do
    signing_secret = System.get_env("STRIPE_ENDPOINT_SECRET")

    [stripe_signature] = Plug.Conn.get_req_header(conn, "stripe-signature")

    with {:ok, body, _} = Plug.Conn.read_body(conn),
         {:ok, stripe_event} = Stripe.Webhook.construct_event(body, stripe_signature, signing_secret)
    do
      Plug.Conn.assign(conn, :stripe_event, stripe_event)
    else
      {:error, error} ->
        conn
        |> send_resp(:bad_request, error.message)
        |> halt()
    end
  end

  def call(conn, _), do: conn
end
