defmodule Ledger.UserOperationsTest do
  use Ledger.RepoCase
  import ExUnit.CaptureIO

  alias Ledger.UserOperations
  alias Ledger.Users
  alias Ledger.Repo

  describe "create_user/2" do
    test "creates a user successfully" do
      UserOperations.create_user("sofia", "2000-01-01")

      # Verify the user was inserted
      user = Repo.get_by(Users, username: "sofia")
      assert user.username == "sofia"
      assert user.birth_date == ~D[2000-01-01]
    end
  end

  describe "edit_user/2" do
    setup do
      {:ok, user} =
        %Users{}
        |> Users.create_changeset(%{username: "juan", birth_date: ~D[2000-01-01]})
        |> Repo.insert()
      %{user: user}
    end

    test "changes the username if valid", %{user: user} do
      UserOperations.edit_user(user.id, "juan_new")
      updated = Repo.get!(Users, user.id)
      assert updated.username == "juan_new"
    end

    test "does not allow using the same username", %{user: user} do
      capture_io(fn ->
        UserOperations.edit_user(user.id, "juan")
      end)

      updated = Repo.get!(Users, user.id)
      assert updated.username == "juan"
    end
  end

  """
  PRIMERO HAY QUE MIGRAR LA TABLA DE TRANSACCIONES
  describe "delete_user/1" do
    setup do
      {:ok, user} =
        %Users{}
        |> Users.create_changeset(%{username: "delete_me", birth_date: ~D[2000-01-01]})
        |> Repo.insert()
      %{user: user}
    end

    test "deletes a user without transactions", %{user: user} do
      UserOperations.delete_user(user.id)
      assert Repo.get(Users, user.id) == nil
    end
  end
"""

  describe "view_user/1" do
    setup do
      {:ok, user} =
        %Users{}
        |> Users.create_changeset(%{username: "view", birth_date: ~D[2000-01-01]})
        |> Repo.insert()
      %{user: user}
    end

    test "shows an existing user", %{user: user} do
      output = capture_io(fn ->
        UserOperations.view_user(user.id)
      end)
      assert String.contains?(output, "view")
    end
  end
end
