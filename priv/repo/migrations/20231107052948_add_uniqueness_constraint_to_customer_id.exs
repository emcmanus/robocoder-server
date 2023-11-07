defmodule Robocoder.Repo.Migrations.AddUniquenessConstraintToCustomerId do
  use Ecto.Migration

  def change do
    drop index(:users, [:stripe_subscription_id])
    drop index(:users, [:stripe_customer_id])
    create unique_index(:users, [:stripe_subscription_id])
    create unique_index(:users, [:stripe_customer_id])
  end
end
