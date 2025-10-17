defmodule Ledger.UsersTest do
  use Ledger.RepoCase
  alias Ledger.Users
  alias Ledger.Repo
  import Ecto.Changeset

  describe "changeset/2" do
    test "creates a valid changeset for a correct user" do
      attrs = %{username: "juan", birth_date: ~D[2000-01-01]}
      changeset = Users.changeset(%Users{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :username) == "juan"
      assert Ecto.Changeset.get_change(changeset, :birth_date) == ~D[2000-01-01]
      assert Ecto.Changeset.get_change(changeset, :edit_date) == Date.utc_today()
    end

    test "fails when username is missing" do
      attrs = %{birth_date: ~D[2000-01-01]}
      changeset = Users.changeset(%Users{}, attrs)

      refute changeset.valid?
      assert %{username: ["Datos incompletos"]} = errors_on(changeset)
    end

    test "fails when birth_date is missing" do
      attrs = %{username: "maria"}
      changeset = Users.changeset(%Users{}, attrs)

      refute changeset.valid?
      assert %{birth_date: ["Datos incompletos"]} = errors_on(changeset)
    end

    test "fails when username is duplicated" do
      # Insertar usuario previo
      Repo.insert!(%Users{username: "juan", birth_date: ~D[2000-01-01]})
      attrs = %{username: "juan", birth_date: ~D[1995-05-05]}
      changeset = Users.changeset(%Users{}, attrs)

      # Validación de unique_constraint requiere Repo.insert para aplicarla
      {:error, changeset} = Repo.insert(changeset)
      assert %{username: ["Ya existe un usuario con ese nombre"]} = errors_on(changeset)
    end

    test "fails if user is under 18" do
      minor_birthdate = Date.add(Date.utc_today(), -17 * 365)
      attrs = %{username: "pepe", birth_date: minor_birthdate}
      changeset = Users.changeset(%Users{}, attrs)

      refute changeset.valid?
      assert %{birth_date: ["Debes ser mayor de 18 años"]} = errors_on(changeset)
    end

    test "succeeds if user is 18 or older" do
      adult_birthdate = Date.add(Date.utc_today(), -18 * 365)
      attrs = %{username: "ana", birth_date: adult_birthdate}
      changeset = Users.changeset(%Users{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :username) == "ana"
    end
  end

  # Helper para extraer errores fácilmente
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
