defmodule RobocoderWeb.ErrorController do
  use RobocoderWeb, :controller

  def error(conn, _params) do
    render(conn, "error.html")
  end
end
