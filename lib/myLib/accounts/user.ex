defmodule MyLib.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :age, :integer
    timestamps(type: :utc_datetime)
  end

  # Remove registration and password changeset logic, keep only basic changeset
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :age])
    |> validate_required([:name, :age])
  end
end
