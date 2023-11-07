defmodule RobocoderWeb.SessionController do
  use RobocoderWeb, :controller

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out.")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end