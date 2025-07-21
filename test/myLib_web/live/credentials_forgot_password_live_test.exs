defmodule MyLibWeb.CredentialsForgotPasswordLiveTest do
  use MyLibWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import MyLib.AccountsFixtures

  alias MyLib.Accounts
  alias MyLib.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/credential/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/credential/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/credential/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_credentials(credentials_fixture())
        |> live(~p"/credential/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{credentials: credentials_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, credentials: credentials} do
      {:ok, lv, _html} = live(conn, ~p"/credential/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", credentials: %{"email" => credentials.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Accounts.CredentialsToken, credentials_id: credentials.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credential/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", credentials: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.CredentialsToken) == []
    end
  end
end
