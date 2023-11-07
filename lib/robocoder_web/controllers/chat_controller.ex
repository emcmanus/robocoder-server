defmodule RobocoderWeb.ChatController do
  use RobocoderWeb, :controller

  def completions(conn, %{"messages" => messages, "functions" => functions, "temperature" => temperature}) do
    # TODO: Implement chat completions
  end
end