defmodule MyLib.Accounts.CredentialsNotifier do
  import Swoosh.Email

  alias MyLib.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"MyLib", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(credentials, url) do
    deliver(credentials.email, "Confirmation instructions", """

    ==============================

    Hi #{credentials.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a credentials password.
  """
  def deliver_reset_password_instructions(credentials, url) do
    deliver(credentials.email, "Reset password instructions", """

    ==============================

    Hi #{credentials.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a credentials email.
  """
  def deliver_update_email_instructions(credentials, url) do
    deliver(credentials.email, "Update email instructions", """

    ==============================

    Hi #{credentials.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
