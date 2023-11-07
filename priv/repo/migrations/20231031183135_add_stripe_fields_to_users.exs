defmodule Robocoder.Repo.Migrations.AddStripeFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stripe_customer_id, :string
      add :subscription_status, :string
    end
  end
end
