defmodule Ledger.Users do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ledger.Transaction
  import Ecto.Query
  alias Ledger.Repo

  schema "users" do
    field :username, :string
    field :birth_date, :date
    field :edit_date, :date

    has_many :transactions_origin, Transaction, foreign_key: :origin_account_id
    has_many :transactions_destination, Transaction, foreign_key: :destination_account_id

    timestamps() # crea automáticamente :inserted_at y :updated_at
  end

  # Changeset para creación
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :birth_date])
    |> validate_required([:username, :birth_date])
    |> unique_constraint(:username)
    |> validate_age()
    |> put_change(:edit_date, Date.utc_today())
  end

  # Devuelve true si se puede actualizar el username, false si no
  def can_update_username?(%__MODULE__{username: current_username}, new_username) do
    if new_username == current_username do
      false
    else
      # verificamos que no exista otro usuario con el mismo nombre
      case Repo.get_by(__MODULE__, username: new_username) do
        nil -> true
        _ -> false
      end
    end
  end



  # Validar que tenga más de 18 años
  defp validate_age(changeset) do
    case get_field(changeset, :birth_date) do
      nil -> changeset
      dob ->
        age = Date.diff(Date.utc_today(), dob) |> div(365)
        if age < 18 do
          add_error(changeset, :birth_date, "User must be at least 18 years old")
        else
          changeset
        end
    end
  end

  # Validación para eliminar usuario: solo si no tiene transacciones
  def delete_allowed?(%__MODULE__{transactions_origin: [], transactions_destination: []}), do: true
  def delete_allowed?(_), do: false
end
