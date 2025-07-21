defmodule MyLib.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias MyLib.Repo

  alias MyLib.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end



  alias MyLib.Accounts.Credentials
  alias MyLib.Accounts.CredentialsToken
  alias MyLib.Accounts.CredentialsNotifier

  ## Database getters

  @doc """
  Gets a credential by email.

  ## Examples

    iex> get_credential_by_email("foo@example.com")
    %Credential{}

    iex> get_credential_by_email("unknown@example.com")
    nil

  """
  def get_credential_by_email(email) when is_binary(email) do
    Repo.get_by(Credentials, email: email)
  end

  @doc """
  Gets a credential by email and password.

  ## Examples

    iex> get_credential_by_email_and_password("foo@example.com", "correct_password")
    %Credential{}

    iex> get_credential_by_email_and_password("foo@example.com", "invalid_password")
    nil

  """
  def get_credential_by_email_and_password(email, password)
    when is_binary(email) and is_binary(password) do
  credential = Repo.get_by(Credentials, email: email)
  if Credentials.valid_password?(credential, password), do: credential
  end

  @doc """
  Gets a single credential.

  Raises `Ecto.NoResultsError` if the Credential does not exist.

  ## Examples

    iex> get_credential!(123)
    %Credential{}

    iex> get_credential!(456)
    ** (Ecto.NoResultsError)

  """
  def get_credential!(id), do: Repo.get!(Credential, id)

  ## Credential registration

  @doc """
  Registers a credential.

    ## Examples

    iex> register_credential(%{field: value})
    {:ok, %Credential{}}

    iex> register_credential(%{field: bad_value})
    {:error, %Ecto.Changeset{}}

  """


  def register_credential(attrs) do
  %Credentials{}
  |> Credentials.registration_changeset(attrs)
  |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking credential changes.

  ## Examples

    iex> change_credential_registration(credential)
    %Ecto.Changeset{data: %Credential{}}

  """
  def change_credential_registration(%Credentials{} = credential, attrs \\ %{}) do
  Credentials.registration_changeset(credential, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
    Returns an `%Ecto.Changeset{}` for changing the credential email.

  ## Examples

    iex> change_credential_email(credential)
    %Ecto.Changeset{data: %Credential{}}

  """
  def change_credential_email(credential, attrs \\ %{}) do
  Credentials.email_changeset(credential, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

    iex> apply_credential_email(credential, "valid password", %{email: ...})
    {:ok, %Credential{}}

    iex> apply_credential_email(credential, "invalid password", %{email: ...})
    {:error, %Ecto.Changeset{}}

  """
  def apply_credential_email(credential, password, attrs) do
  credential
  |> Credentials.email_changeset(attrs)
  |> Credentials.validate_current_password(password)
  |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the credential email using the given token.

  If the token matches, the credential email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_credential_email(credential, token) do
  context = "change:#{credential.email}"

  with {:ok, query} <- CredentialsToken.verify_change_email_token_query(token, context),
       %CredentialsToken{sent_to: email} <- Repo.one(query),
       {:ok, _} <- Repo.transaction(credential_email_multi(credential, email, context)) do
    :ok
  else
    _ -> :error
  end
  end

  defp credential_email_multi(credential, email, context) do
  changeset =
    credential
    |> Credentials.email_changeset(%{email: email})
    |> Credentials.confirm_changeset()

  Ecto.Multi.new()
  |> Ecto.Multi.update(:credential, changeset)
  |> Ecto.Multi.delete_all(:tokens, CredentialsToken.by_credentials_and_contexts_query(credential, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given credential.

  ## Examples

    iex> deliver_credential_update_email_instructions(credential, current_email, &url(~p"/credentials/settings/confirm_email/#{&1}"))
    {:ok, %{to: ..., body: ...}}

  """
  def deliver_credential_update_email_instructions(%Credentials{} = credential, current_email, update_email_url_fun)
    when is_function(update_email_url_fun, 1) do
  {encoded_token, credential_token} = CredentialsToken.build_email_token(credential, "change:#{current_email}")

  Repo.insert!(credential_token)
  CredentialsNotifier.deliver_update_email_instructions(credential, update_email_url_fun.(encoded_token))

  end

  def change_credential_password(credential, attrs \\ %{}) do
  Credentials.password_changeset(credential, attrs, hash_password: false)
  end

  @doc """
  Updates the credential password.

  ## Examples

    iex> update_credential_password(credential, "valid password", %{password: ...})
    {:ok, %Credential{}}

    iex> update_credential_password(credential, "invalid password", %{password: ...})
    {:error, %Ecto.Changeset{}}

  """
  def update_credential_password(credential, password, attrs) do
  changeset =
    credential
    |> Credentials.password_changeset(attrs)
    |> Credentials.validate_current_password(password)

  Ecto.Multi.new()
  |> Ecto.Multi.update(:credential, changeset)
  |> Ecto.Multi.delete_all(:tokens, CredentialsToken.by_credentials_and_contexts_query(credential, :all))
  |> Repo.transaction()
  |> case do
    {:ok, %{credential: credential}} -> {:ok, credential}
    {:error, :credential, changeset, _} -> {:error, changeset}
  end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_credential_session_token(credential) do
  {token, credential_token} = CredentialsToken.build_session_token(credential)
  Repo.insert!(credential_token)
  token
  end

  @doc """
  Gets the credential with the given signed token.
  """
  def get_credential_by_session_token(token) do
  {:ok, query} = CredentialsToken.verify_session_token_query(token)
  Repo.one(query)
  end

  @doc """
    Deletes the signed token with the given context.
  """
  def delete_credential_session_token(token) do
  Repo.delete_all(CredentialsToken.by_token_and_context_query(token, "session"))
  :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given credential.

  ## Examples

    iex> deliver_credential_confirmation_instructions(credential, &url(~p"/credentials/confirm/#{&1}"))
    {:ok, %{to: ..., body: ...}}

    iex> deliver_credential_confirmation_instructions(confirmed_credential, &url(~p"/credentials/confirm/#{&1}"))
    {:error, :already_confirmed}

  """
  def deliver_credential_confirmation_instructions(%Credentials{} = credential, confirmation_url_fun)
    when is_function(confirmation_url_fun, 1) do
  if credential.confirmed_at do
    {:error, :already_confirmed}
  else
    {encoded_token, credential_token} = CredentialsToken.build_email_token(credential, "confirm")
    Repo.insert!(credential_token)
    CredentialsNotifier.deliver_confirmation_instructions(credential, confirmation_url_fun.(encoded_token))
  end
  end

  @doc """
  Confirms a credential by the given token.

  If the token matches, the credential account is marked as confirmed
  and the token is deleted.
  """
  def confirm_credential(token) do
  with {:ok, query} <- CredentialsToken.verify_email_token_query(token, "confirm"),
       %Credentials{} = credential <- Repo.one(query),
       {:ok, %{credential: credential}} <- Repo.transaction(confirm_credential_multi(credential)) do
    {:ok, credential}
  else
    _ -> :error
  end
  end

  defp confirm_credential_multi(credential) do
  Ecto.Multi.new()
  |> Ecto.Multi.update(:credential, Credentials.confirm_changeset(credential))
  |> Ecto.Multi.delete_all(:tokens, CredentialsToken.by_credentials_and_contexts_query(credential, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given credential.

  ## Examples

    iex> deliver_credential_reset_password_instructions(credential, &url(~p"/credentials/reset_password/#{&1}"))
    {:ok, %{to: ..., body: ...}}

  """
  def deliver_credential_reset_password_instructions(%Credentials{} = credential, reset_password_url_fun)
    when is_function(reset_password_url_fun, 1) do
  {encoded_token, credential_token} = CredentialsToken.build_email_token(credential, "reset_password")
  Repo.insert!(credential_token)
  CredentialsNotifier.deliver_reset_password_instructions(credential, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the credential by reset password token.

  ## Examples

    iex> get_credential_by_reset_password_token("validtoken")
    %Credential{}

    iex> get_credential_by_reset_password_token("invalidtoken")
    nil

  """
  def get_credential_by_reset_password_token(token) do
  with {:ok, query} <- CredentialsToken.verify_email_token_query(token, "reset_password"),
       %Credentials{} = credential <- Repo.one(query) do
    credential
  else
    _ -> nil
  end
  end

  @doc """
  Resets the credential password.

  ## Examples

    iex> reset_credential_password(credential, %{password: "new long password", password_confirmation: "new long password"})
    {:ok, %Credential{}}

    iex> reset_credential_password(credential, %{password: "valid", password_confirmation: "not the same"})
    {:error, %Ecto.Changeset{}}

  """
  def reset_credential_password(credential, attrs) do
  Ecto.Multi.new()
  |> Ecto.Multi.update(:credential, Credentials.password_changeset(credential, attrs))
  |> Ecto.Multi.delete_all(:tokens, CredentialsToken.by_credentials_and_contexts_query(credential, :all))
  |> Repo.transaction()
  |> case do
    {:ok, %{credential: credential}} -> {:ok, credential}
    {:error, :credential, changeset, _} -> {:error, changeset}
    end
  end
end
