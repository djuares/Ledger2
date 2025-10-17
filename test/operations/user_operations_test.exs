defmodule Ledger.UserOperationsTest do
  use Ledger.RepoCase
  alias Ledger.{UserOperations, Repo, Users}

  describe "create_user/2" do
    test "creates a user successfully" do
      {:ok, msg} = UserOperations.create_user("Sofía", "2000-01-01")
      assert msg[:crear_usuario] =~ "Usuario creado correctamente con ID"

      user = Repo.get_by(Users, username: "Sofía")
      assert user.birth_date == ~D[2000-01-01]
      assert user.inserted_at != nil
      assert user.updated_at != nil
    end

    test "fails when birthdate is missing" do
      {:error, msg} = UserOperations.create_user("Sofía", "")
      assert msg[:crear_usuario] =~ "Debes ingresar la fecha de nacimiento"
    end

    test "fails with invalid birthdate format" do
      {:error, msg} = UserOperations.create_user("Sofía", "01-01-2000")
      assert msg[:crear_usuario] =~ "Formato de fecha inválido"
    end
  end

  describe "edit_user/2" do
    setup do
      {:ok, msg} = UserOperations.create_user("Mateo", "2000-02-01")
      user = Repo.get_by(Users, username: "Mateo")
      %{user: user}
    end

    test "edits username successfully", %{user: user} do
      {:ok, msg} = UserOperations.edit_user(user.id, "Matías")
      assert msg[:editar_usuario] =~ "Usuario editado correctamente"

      updated = Repo.get(Users, user.id)
      assert updated.username == "Matías"
    end

    test "fails when new name is the same", %{user: user} do
      {:error, msg} = UserOperations.edit_user(user.id, "Mateo")
      assert msg[:editar_usuario] =~ "El nuevo nombre es igual al actual"
    end

    test "fails when user not found" do
      {:error, msg} = UserOperations.edit_user(9999, "NuevoNombre")
      assert msg[:editar_usuario] =~ "Id de usuario 9999 no encontrado"
    end
  end

  describe "delete_user/1" do
    setup do
      {:ok, _} = UserOperations.create_user("Sofía", "2000-01-01")
      user = Repo.get_by(Users, username: "Sofía")
      %{user: user}
    end

    test "deletes a user successfully", %{user: user} do
      {:ok, msg} = UserOperations.delete_user(user.id)
      assert msg[:borrar_usuario] =~ "Usuario borrado correctamente"
      assert Repo.get(Users, user.id) == nil
    end

    test "fails when user not found" do
      {:error, msg} = UserOperations.delete_user(9999)
      assert msg[:editar_usuario] =~ "Id de usuario 9999 no encontrado"
    end
  end

  describe "view_user/1" do
    setup do
      {:ok, _} = UserOperations.create_user("Mateo", "2000-02-01")
      user = Repo.get_by(Users, username: "Mateo")
      %{user: user}
    end

    test "views user successfully", %{user: user} do
      {:ok, msg} = UserOperations.view_user(user.id)
      assert msg[:ver_usuario] =~ "Mateo"
      assert msg[:ver_usuario] =~ "2000-02-01"
    end

    test "fails when user not found" do
      {:error, msg} = UserOperations.view_user(9999)
      assert msg[:view_user] =~ "Usuario con ID 9999 no encontrado"
    end
  end
end
