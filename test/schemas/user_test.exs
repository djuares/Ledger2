defmodule Ledger.UserTest do
  use Ledger.RepoCase

  alias Ledger.Users

  # Helper para mapear errores del changeset a un formato legible
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @valid_attrs %{
    username: "sofia",
    birth_date: ~D[2000-01-01]
  }

  test "create user and verify id, timestamps and validations" do
    # Create User
    {:ok, user} =
      %Users{}
      |> Users.create_changeset(@valid_attrs)
      |> Repo.insert()

    # ID Verification - Primary Key tests
    assert is_integer(user.id) and user.id > 0

    # Verify ID is unique (test uniqueness by creating another user)
    {:ok, user2} =
      %Users{}
      |> Users.create_changeset(%{@valid_attrs | username: "sofia2"})
      |> Repo.insert()

    assert user.id != user2.id  # IDs should be different

    # Verify the record can be retrieved by ID (confirms primary key functionality)
    retrieved_user = Repo.get(Users, user.id)
    assert retrieved_user.id == user.id
    assert retrieved_user.username == user.username

    # Timestamps
    assert %NaiveDateTime{} = user.inserted_at
    assert %NaiveDateTime{} = user.updated_at
    assert user.edit_date == Date.utc_today()

    # Data
    assert user.username == "sofia"
    assert user.birth_date == ~D[2000-01-01]

    # Age Validation
    too_young_attrs = %{username: "young", birth_date: ~D[2010-01-01]}
    changeset = Users.create_changeset(%Users{}, too_young_attrs)
    refute changeset.valid?
    assert {"User must be at least 18 years old", _} = Keyword.get(changeset.errors, :birth_date)
    end

  test "username debe ser único" do
      {:ok, _user} =
        %Users{}
        |> Users.create_changeset(%{username: "sofia", birth_date: ~D[2000-01-01]})
        |> Repo.insert()

      {:error, changeset} =
        %Users{}
        |> Users.create_changeset(%{username: "sofia", birth_date: ~D[1999-01-01]})
        |> Repo.insert()

      assert "has already been taken" in errors_on(changeset).username
    end


end
