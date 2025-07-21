defmodule MyLibWeb.CredentialsSessionController do
  use MyLibWeb, :controller

  alias MyLib.Accounts
  alias MyLibWeb.CredentialsAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:credentials_return_to, ~p"/credential/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"credentials" => credentials_params}, info) do
    %{"email" => email, "password" => password} = credentials_params

    if credentials = Accounts.get_credential_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> CredentialsAuth.log_in_credential(credentials, credentials_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/credential/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> CredentialsAuth.log_out_credentials()
  end
end
