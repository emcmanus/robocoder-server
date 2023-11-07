defmodule Robocoder.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email,     :string,  null: false
      add :balance,   :decimal, null: false, precision: 20, scale: 8, default: 0.0
      add :api_token, :string,  null: false
      add :scope,     :string,  null: false

      add :access_token, :string

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:api_token])
  end
end
