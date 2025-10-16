defmodule Ledger.UserOperations do
  alias Ledger.{Repo, Users}

def create_user(username, birthdate) do
  if is_nil(birthdate) or birthdate == "" do
    {:error, crear_usuario: "Debes ingresar la fecha de nacimiento (-b=YYYY-MM-DD)"}
  else
    case Date.from_iso8601(birthdate) do
      {:ok, date} ->
        %Users{}
        |> Users.changeset(%{username: username, birth_date: date})
        |> Repo.insert()
        |> case do
          {:ok, user} ->
            {:ok, crear_usuario: "Usuario creado correctamente con ID #{user.id}"}

          {:error, changeset} ->
            errors =
              changeset
              |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
              |> Enum.flat_map(fn {_field, messages} -> messages end)
              |> Enum.join("; ")

            {:error, crear_usuario: errors}
        end
      {:error, _reason} ->
        {:error, crear_usuario: "Formato de fecha inválido (YYYY-MM-DD)"}
    end
  end
end
  def edit_user(id, new_name) do
    case Repo.get(Users, id) do
      nil ->
        {:error, editar_usuario: "Id de usuario #{id} no encontrado"}

      user ->
        if user.username == new_name do
          {:error, editar_usuario: "El nuevo nombre es igual al actual"}
        else
          user
          |> Users.changeset(%{username: new_name})
          |> Repo.update()
          |> case do
            {:ok, _} ->
              {:ok, editar_usuario: "Usuario editado correctamente"}

            {:error, changeset} ->
              errors =
                changeset
                |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
                |> Enum.flat_map(fn {_field, messages} -> messages end)
                |> Enum.join("; ")

              {:error, editar_usuario: errors}
          end
        end
    end
  end

  def delete_allowed?(user) do
    user = Repo.preload(user, [:transactions_origin, :transactions_destination])
    user.transactions_origin == [] and user.transactions_destination == []
  end

  def delete_user(id) do
    case Repo.get(Users, id) do
      nil -> {:error, editar_usuario: "Id de usuario #{id} no encontrado"}
      user ->
        if delete_allowed?(user) do
          Repo.delete(user)
          {:ok, borrar_usuario: "Usuario borrado correctamente"}
        else
          {:error, borrar_usuario: "No se puede borrar usuario: tiene transacciones asociadas"}
        end
    end
  end

def view_user(id) do
  case Repo.get(Users, id) do
    nil ->
      {:error, view_user: "User not found"}

    user ->
      user_str = """
      id= #{user.id}
      username: #{user.username}
      birth_date: #{Date.to_string(user.birth_date)}
      edit_date: #{Date.to_string(user.edit_date)}
      inserted_at: #{NaiveDateTime.to_string(user.inserted_at)}
      """
      {:ok, ver_usuario: String.trim(user_str)}
  end
end

end
