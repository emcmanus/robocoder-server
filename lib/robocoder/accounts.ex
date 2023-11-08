defmodule Robocoder.Accounts do
  import Ecto.Query, warn: false
  alias Robocoder.Repo
  alias Robocoder.Accounts.User

  def get_user_by_stripe_customer_id_or_user_id(customer_id, user_id) do
    user = User
    |> where([u], u.stripe_customer_id == ^customer_id)
    |> Repo.one()
    user || get_user(user_id)
  end

  def get_user_by_stripe_customer_id(stripe_customer_id) do
    User
    |> where([u], u.stripe_customer_id == ^stripe_customer_id)
    |> Repo.one()
  end

  def get_user_by_stripe_subscription_id(stripe_subscription_id) do
    User
    |> where([u], u.stripe_subscription_id == ^stripe_subscription_id)
    |> Repo.one()
  end

  def update_user_subscription_from_session(user, session, status) do
    changeset = Ecto.Changeset.change(user, subscription_status: status, stripe_customer_id: session.customer, stripe_subscription_id: session.subscription)
    Repo.update(changeset)
  end

  def update_user_subscription_status(user, new_status) when is_binary(new_status) do
    changeset = Ecto.Changeset.change(user, subscription_status: new_status)
    Repo.update(changeset)
  end

  def update_stripe_customer_id(user, stripe_customer_id) do
    changeset = Ecto.Changeset.change(user, stripe_customer_id: stripe_customer_id)
    Repo.update(changeset)
  end

  def update_stripe_subscription_id(user, stripe_subscription_id) do
    changeset = Ecto.Changeset.change(user, stripe_subscription_id: stripe_subscription_id)
    Repo.update(changeset)
  end

  def get_user_by_api_token(api_token) do
    User
    |> where([u], u.api_token == ^api_token)
    |> Repo.one()
  end

  def get_user_by_email(email) do
    User
    |> where([u], u.email == ^email)
    |> Repo.one()
  end

  def create_user(attrs \\ %{}) do
    api_token_prefix = Application.get_env(:robocoder, :api_token_prefix)
    attrs = Map.merge(%{balance: 0, api_token: api_token_prefix <> UUID.uuid4(), scope: "email:read"}, attrs)
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user(id) do
    Repo.get(User, id)
  end
end
