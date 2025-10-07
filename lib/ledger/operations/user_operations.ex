defmodule Ledger.UserOperations do
  alias Ledger.{Repo}
  alias Ledger.Users

  # Create user

  def create_user(username, birthdate) do
    birthdate = Date.from_iso8601!(birthdate)

    %Users{}
    |> Users.create_changeset(%{
      username: username,
      birth_date: birthdate
    })
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        {:ok, "User created successfully with ID #{user.id}"}

      {:error, changeset} ->
        {:error, changeset}
    end
  end



  # Validate if username can be updated
  def can_update_username?(%Users{username: current_username}, new_username) do
    if new_username == current_username do
      false
    else
      case Repo.get_by(Users, username: new_username) do
        nil -> true
        _ -> false
      end
    end
  end

  # Edit user
  def edit_user(id, new_name) do
    case Repo.get(Users, id) do
      nil ->
        IO.puts("⚠️ User with ID #{id} not found.")

      user ->
        if can_update_username?(user, new_name) do
          user
          |> Users.create_changeset(%{username: new_name})
          |> Repo.update()
          |> case do
            {:ok, _} -> IO.puts("✅ User updated successfully.")
            {:error, changeset} ->
              IO.puts("❌ Error updating user:")
              IO.inspect(changeset.errors)
          end
        else
          IO.puts("⚠️ That username cannot be used.")
        end
    end
  end

  # Validation to delete user
  def delete_allowed?(user) do
    user = Repo.preload(user, [:transactions_origin, :transactions_destination])

    user.transactions_origin == [] and user.transactions_destination == []
  end

  # Delete user
  def delete_user(id) do
    case Repo.get(Users, id) do
      nil ->
        IO.puts("⚠️ User with ID #{id} not found.")

      user ->
        if delete_allowed?(user) do
          Repo.delete(user)
          IO.puts("🗑️ User deleted successfully.")
        else
          IO.puts("⚠️ Cannot delete user: user has associated transactions.")
        end
    end
  end

  # View user
  def view_user(id) do
    case Repo.get(Users, id) do
      nil -> IO.puts("⚠️ User not found.")
      user -> IO.inspect(user)
    end
  end
end
