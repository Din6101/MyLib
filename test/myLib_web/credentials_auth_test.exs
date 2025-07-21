defmodule MyLibWeb.CredentialsAuthTest do
  use MyLibWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias MyLib.Accounts
  alias MyLibWeb.CredentialsAuth
  import MyLib.AccountsFixtures

  @remember_me_cookie "_my_lib_web_credentials_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, MyLibWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{credentials: credentials_fixture(), conn: conn}
  end

  describe "log_in_credentials/3" do
    test "stores the credentials token in the session", %{conn: conn, credentials: credentials} do
      conn = CredentialsAuth.log_in_credentials(conn, credentials)
      assert token = get_session(conn, :credentials_token)
      assert get_session(conn, :live_socket_id) == "credential_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_credentials_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, credentials: credentials} do
      conn = conn |> put_session(:to_be_removed, "value") |> CredentialsAuth.log_in_credentials(credentials)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, credentials: credentials} do
      conn = conn |> put_session(:credentials_return_to, "/hello") |> CredentialsAuth.log_in_credentials(credentials)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, credentials: credentials} do
      conn = conn |> fetch_cookies() |> CredentialsAuth.log_in_credentials(credentials, %{"remember_me" => "true"})
      assert get_session(conn, :credentials_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :credentials_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_credentials/1" do
    test "erases session and cookies", %{conn: conn, credentials: credentials} do
      credentials_token = Accounts.generate_credentials_session_token(credentials)

      conn =
        conn
        |> put_session(:credentials_token, credentials_token)
        |> put_req_cookie(@remember_me_cookie, credentials_token)
        |> fetch_cookies()
        |> CredentialsAuth.log_out_credentials()

      refute get_session(conn, :credentials_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_credentials_by_session_token(credentials_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "credential_sessions:abcdef-token"
      MyLibWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> CredentialsAuth.log_out_credentials()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if credentials is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> CredentialsAuth.log_out_credentials()
      refute get_session(conn, :credentials_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_credentials/2" do
    test "authenticates credentials from session", %{conn: conn, credentials: credentials} do
      credentials_token = Accounts.generate_credentials_session_token(credentials)
      conn = conn |> put_session(:credentials_token, credentials_token) |> CredentialsAuth.fetch_current_credentials([])
      assert conn.assigns.current_credentials.id == credentials.id
    end

    test "authenticates credentials from cookies", %{conn: conn, credentials: credentials} do
      logged_in_conn =
        conn |> fetch_cookies() |> CredentialsAuth.log_in_credentials(credentials, %{"remember_me" => "true"})

      credentials_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> CredentialsAuth.fetch_current_credentials([])

      assert conn.assigns.current_credentials.id == credentials.id
      assert get_session(conn, :credentials_token) == credentials_token

      assert get_session(conn, :live_socket_id) ==
               "credential_sessions:#{Base.url_encode64(credentials_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, credentials: credentials} do
      _ = Accounts.generate_credentials_session_token(credentials)
      conn = CredentialsAuth.fetch_current_credentials(conn, [])
      refute get_session(conn, :credentials_token)
      refute conn.assigns.current_credentials
    end
  end

  describe "on_mount :mount_current_credentials" do
    test "assigns current_credentials based on a valid credentials_token", %{conn: conn, credentials: credentials} do
      credentials_token = Accounts.generate_credentials_session_token(credentials)
      session = conn |> put_session(:credentials_token, credentials_token) |> get_session()

      {:cont, updated_socket} =
        CredentialsAuth.on_mount(:mount_current_credentials, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_credentials.id == credentials.id
    end

    test "assigns nil to current_credentials assign if there isn't a valid credentials_token", %{conn: conn} do
      credentials_token = "invalid_token"
      session = conn |> put_session(:credentials_token, credentials_token) |> get_session()

      {:cont, updated_socket} =
        CredentialsAuth.on_mount(:mount_current_credentials, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_credentials == nil
    end

    test "assigns nil to current_credentials assign if there isn't a credentials_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        CredentialsAuth.on_mount(:mount_current_credentials, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_credentials == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_credentials based on a valid credentials_token", %{conn: conn, credentials: credentials} do
      credentials_token = Accounts.generate_credentials_session_token(credentials)
      session = conn |> put_session(:credentials_token, credentials_token) |> get_session()

      {:cont, updated_socket} =
        CredentialsAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_credentials.id == credentials.id
    end

    test "redirects to login page if there isn't a valid credentials_token", %{conn: conn} do
      credentials_token = "invalid_token"
      session = conn |> put_session(:credentials_token, credentials_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: MyLibWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = CredentialsAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_credentials == nil
    end

    test "redirects to login page if there isn't a credentials_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: MyLibWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = CredentialsAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_credentials == nil
    end
  end

  describe "on_mount :redirect_if_credentials_is_authenticated" do
    test "redirects if there is an authenticated  credentials ", %{conn: conn, credentials: credentials} do
      credentials_token = Accounts.generate_credentials_session_token(credentials)
      session = conn |> put_session(:credentials_token, credentials_token) |> get_session()

      assert {:halt, _updated_socket} =
               CredentialsAuth.on_mount(
                 :redirect_if_credentials_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated credentials", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               CredentialsAuth.on_mount(
                 :redirect_if_credentials_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_credentials_is_authenticated/2" do
    test "redirects if credentials is authenticated", %{conn: conn, credentials: credentials} do
      conn = conn |> assign(:current_credentials, credentials) |> CredentialsAuth.redirect_if_credentials_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if credentials is not authenticated", %{conn: conn} do
      conn = CredentialsAuth.redirect_if_credentials_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_credentials/2" do
    test "redirects if credentials is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> CredentialsAuth.require_authenticated_credentials([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/credential/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> CredentialsAuth.require_authenticated_credentials([])

      assert halted_conn.halted
      assert get_session(halted_conn, :credentials_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> CredentialsAuth.require_authenticated_credentials([])

      assert halted_conn.halted
      assert get_session(halted_conn, :credentials_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> CredentialsAuth.require_authenticated_credentials([])

      assert halted_conn.halted
      refute get_session(halted_conn, :credentials_return_to)
    end

    test "does not redirect if credentials is authenticated", %{conn: conn, credentials: credentials} do
      conn = conn |> assign(:current_credentials, credentials) |> CredentialsAuth.require_authenticated_credentials([])
      refute conn.halted
      refute conn.status
    end
  end
end
