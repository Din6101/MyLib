defmodule MyLibWeb.CredentialsSettingsLiveTest do
  use MyLibWeb.ConnCase, async: true

  alias MyLib.Accounts
  import Phoenix.LiveViewTest
  import MyLib.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_credentials(credentials_fixture())
        |> live(~p"/credential/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if credentials is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/credential/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credential/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_credentials_password()
      credentials = credentials_fixture(%{password: password})
      %{conn: log_in_credentials(conn, credentials), credentials: credentials, password: password}
    end

    test "updates the credentials email", %{conn: conn, password: password, credentials: credentials} do
      new_email = unique_credentials_email()

      {:ok, lv, _html} = live(conn, ~p"/credential/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "credentials" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_credentials_by_email(credentials.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credential/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "credentials" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, credentials: credentials} do
      {:ok, lv, _html} = live(conn, ~p"/credential/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "credentials" => %{"email" => credentials.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_credentials_password()
      credentials = credentials_fixture(%{password: password})
      %{conn: log_in_credentials(conn, credentials), credentials: credentials, password: password}
    end

    test "updates the credentials password", %{conn: conn, credentials: credentials, password: password} do
      new_password = valid_credentials_password()

      {:ok, lv, _html} = live(conn, ~p"/credential/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "credentials" => %{
            "email" => credentials.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/credential/settings"

      assert get_session(new_password_conn, :credentials_token) != get_session(conn, :credentials_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_credentials_by_email_and_password(credentials.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credential/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "credentials" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credential/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "credentials" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      credentials = credentials_fixture()
      email = unique_credentials_email()

      token =
        extract_credentials_token(fn url ->
          Accounts.deliver_credentials_update_email_instructions(%{credentials | email: email}, credentials.email, url)
        end)

      %{conn: log_in_credentials(conn, credentials), token: token, email: email, credentials: credentials}
    end

    test "updates the credentials email once", %{conn: conn, credentials: credentials, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/credential/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credential/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_credentials_by_email(credentials.email)
      assert Accounts.get_credentials_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/credential/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credential/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, credentials: credentials} do
      {:error, redirect} = live(conn, ~p"/credential/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credential/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_credentials_by_email(credentials.email)
    end

    test "redirects if credentials is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/credential/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credential/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
