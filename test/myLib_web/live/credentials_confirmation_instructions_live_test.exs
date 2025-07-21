defmodule MyLibWeb.CredentialsConfirmationInstructionsLiveTest do
  use MyLibWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import MyLib.AccountsFixtures

  alias MyLib.Accounts
  alias MyLib.Repo

  setup do
    %{credentials: credentials_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/credential/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, credentials: credentials} do
      {:ok, lv, _html} = live(conn, ~p"/credential/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", credentials: %{email: credentials.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.CredentialsToken, credentials_id: credentials.id).context == "confirm"
    end

    test "does not send confirmation token if credentials is confirmed", %{conn: conn, credentials: credentials} do
      Repo.update!(Accounts.Credentials.confirm_changeset(credentials))

      {:ok, lv, _html} = live(conn, ~p"/credential/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", credentials: %{email: credentials.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.CredentialsToken, credentials_id: credentials.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credential/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", credentials: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.CredentialsToken) == []
    end
  end
end
