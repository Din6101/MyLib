defmodule MyLib.Accounts.Loan do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyLib.Accounts.Book
  alias MyLib.Accounts.User

  schema "loans" do
    field :borrows_at, :naive_datetime
    field :due_at, :naive_datetime
    field :returned_at, :naive_datetime

    belongs_to :user, User
    belongs_to :book, Book

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(loan, attrs) do
    loan
    |> cast(attrs, [:borrows_at, :due_at, :user_id, :book_id, :returned_at])
    |> validate_required([:borrows_at, :due_at, :user_id, :book_id])
    |> cast_assoc(:user)
    |> cast_assoc(:book)
  end
end
