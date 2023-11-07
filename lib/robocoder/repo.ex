defmodule Robocoder.Repo do
  use Ecto.Repo,
    otp_app: :robocoder,
    adapter: Ecto.Adapters.Postgres
end
