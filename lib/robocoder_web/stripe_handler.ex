defmodule RobocoderWeb.StripeHandler do
  alias Robocoder.Accounts

  @behaviour Stripe.WebhookHandler

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed", data: %{object: session}} = _event) do
    process_checkout_session_completed(session)
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.deleted", data: %{object: subscription}} = _event) do
    process_subscription_deleted(subscription)
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.updated", data: %{object: subscription}} = _event) do
    process_subscription_updated(subscription)
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(_event), do: :ok

  #

  def process_checkout_session_completed(session) do
    case Accounts.get_user_by_stripe_customer_id_or_user_id(session.customer, session.metadata["user_id"]) do
      nil ->
        {:error, "User not found"}

      user ->
        {:ok, _} = Accounts.update_user_subscription_from_session(user, session, "active")
        :ok
    end
  end

  def process_subscription_deleted(subscription) do
    user = Accounts.get_user_by_stripe_subscription_id(subscription.id)
    if user do
      {:ok, _} = Accounts.update_user_subscription_status(user, "canceled")
      :ok
    else
      {:error, "Subscription not found"}
    end
  end

  def process_subscription_updated(subscription) do
    user = Accounts.get_user_by_stripe_subscription_id(subscription.id)
    if user do
      new_status = case subscription.status do
        "active" -> "active"
        "past_due" -> "past_due"
        "canceled" -> "canceled"
        "unpaid" -> "unpaid"
        _ -> "unknown"
      end
      {:ok, _} = Accounts.update_user_subscription_status(user, new_status)
      :ok
    else
      {:error, "Subscription not found"}
    end
  end

end
