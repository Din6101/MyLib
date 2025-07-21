defmodule MyLibWeb.CredentialsSessionControllerTest do
  use MyLibWeb.ConnCase, async: true

  import MyLib.AccountsFixtures

  setup do
    %{credentials: credentials_fixture()}
  end

  describe "POST /credential/log_in" do
    test "logs the credentials in", %{conn: conn, credentials: credentials} do
      conn =
        post(conn, ~p"/credential/log_in", %{
          "credentials" => %{"email" => credentials.email, "password" => valid_credentials_password()}
        })

      assert get_session(conn, :credentials_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ credentials.email
      assert response =~ ~p"/credential/settings"
      assert response =~ ~p"/credential/log_out"
    end

    test "logs the credentials in with remember me", %{conn: conn, credentials: credentials} do
      conn =
        post(conn, ~p"/credential/log_in", %{
          "credentials" => %{
            "email" => credentials.email,
            "password" => valid_credentials_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_my_lib_web_credentials_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the credentials in with return to", %{conn: conn, credentials: credentials} do
      conn =
        conn
        |> init_test_session(credentials_return_to: "/foo/bar")
        |> post(~p"/credential/log_in", %{
          "credentials" => %{
            "email" => credentials.email,
            "password" => valid_credentials_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, credentials: credentials} do
      conn =
        conn
        |> post(~p"/credential/log_in", %{
          "_action" => "registered",
          "credentials" => %{
            "email" => credentials.email,
            "password" => valid_credentials_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, credentials: credentials} do
      conn =
        conn
        |> post(~p"/credential/log_in", %{
          "_action" => "password_updated",
          "credentials" => %{
            "email" => credentials.email,
            "password" => valid_credentials_password()
          }
        })

      assert redirected_to(conn) == ~p"/credential/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/credential/log_in", %{
          "credentials" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/credential/log_in"
    end
  end

  describe "DELETE /credential/log_out" do
    test "logs the credentials out", %{conn: conn, credentials: credentials} do
      conn = conn |> log_in_credentials(credentials) |> delete(~p"/credential/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :credentials_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the credentials is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/credential/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :credentials_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
