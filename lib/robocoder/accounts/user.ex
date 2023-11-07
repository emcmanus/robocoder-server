defmodule Robocoder.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :balance, :decimal
    field :api_token, :string
    field :access_token, :string
    field :scope, :string
    field :stripe_customer_id, :string
    field :stripe_subscription_id, :string
    field :subscription_status, :string
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :balance, :api_token, :access_token, :scope, :stripe_subscription_id, :stripe_customer_id, :subscription_status])
    |> validate_required([:email, :balance, :api_token, :scope])
    |> unique_constraint(:email)
    |> unique_constraint(:api_token)
  end
end
