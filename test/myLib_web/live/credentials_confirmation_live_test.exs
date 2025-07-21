defmodule MyLibWeb.CredentialsConfirmationLiveTest do
  use MyLibWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import MyLib.AccountsFixtures

  alias MyLib.Accounts
  alias MyLib.Repo

  setup do
    %{credentials: credentials_fixture()}
  end

  describe "Confirm credentials" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/credential/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, credentials: credentials} do
      token =
        extract_credentials_token(fn url ->
          Accounts.deliver_credentials_confirmation_instructions(credentials, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/credential/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Credentials confirmed successfully"

      assert Accounts.get_credentials!(credentials.id).confirmed_at
      refute get_session(conn, :credentials_token)
      assert Repo.all(Accounts.CredentialsToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/credential/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Credentials confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_credentials(credentials)

      {:ok, lv, _html} = live(conn, ~p"/credential/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, credentials: credentials} do
      {:ok, lv, _html} = live(conn, ~p"/credential/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Credentials confirmation link is invalid or it has expired"

      refute Accounts.get_credentials!(credentials.id).confirmed_at
    end
  end
end
