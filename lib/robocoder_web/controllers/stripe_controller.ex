defmodule RobocoderWeb.StripeController do
  use RobocoderWeb, :controller
  alias Robocoder.Accounts

  # See stripe_webhook_plug.ex for the implementation of this plug

  def webhook(%Plug.Conn{assigns: %{stripe_event: stripe_event}} = conn, _params) do
    handle_webhook(stripe_event, conn)
  end

  defp handle_webhook(%{type: "checkout.session.completed", data: %{object: session}} = _stripe_event, conn) do
    process_checkout_session_completed(conn, session)
  end

  defp handle_webhook(%{type: "customer.subscription.deleted", data: %{object: subscription}} = _stripe_event, conn) do
    process_subscription_deleted(conn, subscription)
  end

  defp handle_webhook(%{type: "customer.subscription.updated", data: %{object: subscription}} = _stripe_event, conn) do
    process_subscription_updated(conn, subscription)
  end

  defp process_checkout_session_completed(conn, session) do
    case Accounts.get_user_by_stripe_customer_id_or_user_id(session.customer, session.metadata["user_id"]) do
      nil ->
        send_resp(conn, 404, "User not found")

      user ->
        Accounts.update_user_subscription_from_session(user, session, "active")
        send_resp(conn, 200, "")
    end
  end

  defp process_subscription_deleted(conn, subscription) do
    user = Accounts.get_user_by_stripe_subscription_id(subscription.id)
    if user do
      Accounts.update_user_subscription_status(user, "canceled")
      send_resp(conn, 200, "")
    else
      send_resp(conn, 404, "User not found")
    end
  end

  defp process_subscription_updated(conn, subscription) do
    user = Accounts.get_user_by_stripe_subscription_id(subscription.id)
    if user do
      new_status = case subscription.status do
        "active" -> "active"
        "past_due" -> "past_due"
        "canceled" -> "canceled"
        "unpaid" -> "unpaid"
        _ -> "unknown"
      end

      Accounts.update_user_subscription_status(user, new_status)
      send_resp(conn, 200, "")
    else
      send_resp(conn, 404, "User not found")
    end
  end
end
