defmodule YourApp.Repo.Migrations.AddStripeSubscriptionIdToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stripe_subscription_id, :string
    end

    create index(:users, [:stripe_subscription_id])
    create index(:users, [:stripe_customer_id])
  end
end
