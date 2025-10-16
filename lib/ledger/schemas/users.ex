defmodule Ledger.Users do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ledger.Transaction

  schema "users" do
    field :username, :string
    field :birth_date, :date
    field :edit_date, :date

    has_many :transactions_origin, Transaction, foreign_key: :origin_account_id
    has_many :transactions_destination, Transaction, foreign_key: :destination_account_id

    timestamps() # crea automáticamente :inserted_at y :updated_at
  end

  def changeset(user, attrs) do
  user
  |> cast(attrs, [:username, :birth_date])
  |> validate_required([:username, :birth_date], message: "Datos incompletos")
  |> unique_constraint(:username, message: "Ya existe un usuario con ese nombre")
  |> validate_age()
  |> put_change(:edit_date, Date.utc_today())
end

  defp validate_age(changeset) do
    case get_field(changeset, :birth_date) do
      nil -> changeset
      dob ->
        age = Date.diff(Date.utc_today(), dob) |> div(365)
        if age < 18 do
          add_error(changeset, :birth_date, "Debes ser mayor de 18 años")
        else
          changeset
        end
    end
  end

end
