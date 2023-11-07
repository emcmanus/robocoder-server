defmodule RobocoderWeb.AccountsController do
  use RobocoderWeb, :controller
  alias Robocoder.Accounts

  def github_auth(conn, _params) do
    redirect(conn, external: "https://github.com/login/oauth/authorize?client_id=#{System.get_env("GITHUB_CLIENT_ID")}&redirect_uri=#{System.get_env("GITHUB_REDIRECT_URI")}&scope=user:email")
  end

  def github_callback(conn, %{"code" => code}) do

    body = Jason.encode!(%{
      client_id: System.get_env("GITHUB_CLIENT_ID"),
      client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
      code: code,
      redirect_uri: System.get_env("GITHUB_REDIRECT_URI"),
    })

    headers = [
      {"Accept", "application/json"},
      {"Content-Type", "application/json"}
    ]

    token_response = HTTPoison.post("https://github.com/login/oauth/access_token", body, headers)

    case token_response do
      {:ok, %HTTPoison.Response{body: body}} ->
        access_token = Jason.decode!(body)["access_token"]

        if access_token do
          user_response = HTTPoison.get("https://api.github.com/user/emails", ["Authorization": "Bearer #{access_token}"])

          case user_response do
            {:ok, %HTTPoison.Response{body: user_body}} ->
              case get_primary_email(user_body) do
                {:ok, email} ->
                  user = Accounts.get_user_by_email(email)

                  if user do
                    conn
                    |> put_session(:user_id, user.id)
                    |> assign(:current_user, user)
                    |> redirect(to: "/")
                  else
                    {:ok, user} = Accounts.create_user(%{email: email, access_token: access_token})
                    conn
                    |> put_session(:user_id, user.id)
                    |> assign(:current_user, user)
                    |> redirect(to: "/")
                  end
                {:error, reason} ->
                  # Handle the error, maybe logging it and redirecting to an error page
                  conn
                  |> put_flash(:error, reason)
                  |> redirect(to: "/error")
              end
            {:error, %HTTPoison.Error{reason: reason}} ->
              # Handle the HTTP error, e.g., logging and redirecting to an error page
              conn
              |> put_flash(:error, "Failed to fetch user emails: #{reason}")
              |> redirect(to: "/error")
          end
        else
          # Handle the missing access token error
          conn
          |> put_flash(:error, "Access token is missing.")
          |> redirect(to: "/error")
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        # Handle the error from the access token request, e.g., logging and redirecting to an error page
        conn
        |> put_flash(:error, "Failed to obtain access token: #{reason}")
        |> redirect(to: "/error")
    end
  end

  # Called a "license key" in the extension, called an "api key" in a few places here
  def validate_license_key(conn, %{"license_key" => license_key}) do
    user = Accounts.get_user_by_api_token(license_key)

    if user && user.subscription_status == "active" do
      json(conn, %{valid: true})
    else
      json(conn, %{valid: false})
    end
  end

  def balance(conn, _params) do
    api_token = get_req_header(conn, "authorization")
               |> List.first()
               |> String.replace("Bearer ", "")

    user = Robocoder.Accounts.get_user_by_api_token(api_token)

    if user do
      json(conn, %{balance: user.balance})
    else
      conn
        |> put_status(:unauthorized)
        |> json(%{message: "Not authenticated"})
    end
  end

  def get_primary_email(response_body) do
    decoded = Jason.decode!(response_body)

    # Check if decoded is a map and has a "message" key
    if is_map(decoded) and Map.has_key?(decoded, "message") do
      {:error, decoded["message"]}
    else
      # We expect decoded to be a list of emails at this point
      primary_email_map = Enum.find(decoded, fn email ->
        email["primary"] && email["verified"]
      end)

      case primary_email_map do
        nil ->
          {:error, "Primary, verified email not found."}
        email_map ->
          {:ok, email_map["email"]}
      end
    end
  end

end
