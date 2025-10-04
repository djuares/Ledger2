defmodule Ledger.UserTest do
  use Ledger.RepoCase
  alias Ledger.Users

  @valid_attrs %{
    username: "sofia",
    birth_date: ~D[2000-01-01]
  }

  test "create user and verify id, timestamps and validations" do
    # Creación de usuario
    {:ok, user} =
      %Users{}
      |> Users.create_changeset(@valid_attrs)
      |> Repo.insert()

    # Actualización de username
    # Mismo username -> no se puede actualizar
    refute Ledger.Users.can_update_username?(user, "sofia")

    # Nuevo username -> se puede actualizar
    assert Ledger.Users.can_update_username?(user, "mateo")

    # ID
    assert is_integer(user.id) and user.id > 0

    # Timestamps
    assert %NaiveDateTime{} = user.inserted_at
    assert %NaiveDateTime{} = user.updated_at
    assert user.edit_date == Date.utc_today()

    # Datos
    assert user.username == "sofia"
    assert user.birth_date == ~D[2000-01-01]

    # Validación de edad
    too_young_attrs = %{username: "young", birth_date: ~D[2010-01-01]}
    changeset = Users.create_changeset(%Users{}, too_young_attrs)
    refute changeset.valid?
    assert {"User must be at least 18 years old", _} = Keyword.get(changeset.errors, :birth_date)

    # Validación de transacciones
    user_with_tx = %Users{transactions_origin: [%{}], transactions_destination: []}
    refute Users.delete_allowed?(user_with_tx)

    user_no_tx = %Users{transactions_origin: [], transactions_destination: []}
    assert Users.delete_allowed?(user_no_tx)



  end
end
