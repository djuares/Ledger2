defmodule Ledger.MoneyOperations do
  alias Ledger.{Repo, Money}

  @doc """
  Creates a new Money record with the given name and USD price.
  """
def create_money(money_name, usd_price) do
  %Money{}
  |> Money.changeset(%{name: money_name, price: usd_price})
  |> Ecto.Changeset.validate_length(:name, min: 3, max: 4)
  |> Repo.insert()
  |> case do
    {:ok, money} ->
      {:ok, crear_moneda: "Moneda creada correctamente con ID #{money.id}"}
    {:error, changeset} ->
      message =
        changeset
        |> Ecto.Changeset.traverse_errors(fn {msg, _opts} ->
          if String.contains?(msg, "should be at least") do
            "El nombre debe tener entre 3 y 4 caracteres"
          else
            msg
          end
        end)
        |> Enum.map(fn {campo, msgs} -> "#{campo}: #{Enum.join(msgs, ", ")}" end)
        |> Enum.join("; ")

      {:error, crear_moneda: message}

  end
end
  @doc """
  Updates the USD price of a Money record given its ID.
  """
  def edit_money(id, new_price) do
    case Repo.get(Money, id) do
      nil ->
        {:error, editar_moneda: "Money with ID #{id} not found"}
      money ->
        money
        |> Money.changeset(%{price: new_price})
        |> Repo.update()
        |> case do
          {:ok, _updated} ->
            {:ok, editar_moneda: "Money with ID #{id} updated successfully"}
          {:error, changeset} ->
            message =
              changeset
              |> Ecto.Changeset.traverse_errors(fn {msg, _opts} ->
                if String.contains?(msg, "should be at least") do
                  "El nombre debe tener entre 3 y 4 caracteres"
                else
                  msg
                end
              end)
              |> Enum.map(fn {campo, msgs} -> "#{campo}: #{Enum.join(msgs, ", ")}" end)
              |> Enum.join("; ")

            {:error, crear_moneda: message}
        end
    end
  end

  @doc """
  Returns true if the money entity can be deleted (no transactions associated).
  """
  def delete_allowed?(money) do
    money = Ledger.Repo.preload(money, [:transactions_as_origin, :transactions_as_destination])
    Enum.empty?(money.transactions_as_origin) and Enum.empty?(money.transactions_as_destination)
  end

  @doc """
  Deletes a Money record given its ID, only if it has no associated transactions.
  """
  def delete_money(id) do
    case Repo.get(Money, id) do
      nil ->
        {:error, borrar_moneda: "Money with ID #{id} not found"}
      money ->
        money = Repo.preload(money, [:transactions_as_origin, :transactions_as_destination])
        if delete_allowed?(money) do
          case Repo.delete(money) do
            {:ok, _struct} ->
              {:ok, "Money with ID #{id} deleted successfully"}
            {:error, changeset} ->
              {:error, borrar_moneda:  changeset}
          end
        else
          {:error, borrar_moneda:  "Cannot delete Money with ID #{id} because it has associated transactions"}
        end
    end
  end
  @doc """
  Retrieves a Money record by its ID.
  """
  def show_money(id) do
    case Repo.get(Money, id) do
      nil ->
        {:error, ver_moneda: "Moneda no encontrada"}

      money ->
        money_str = """
        id= #{money.id}
        name: #{money.name}
        price: #{money.price}
        inserted_at: #{NaiveDateTime.to_string(money.inserted_at)}
        updated_at: #{NaiveDateTime.to_string(money.updated_at)}
        """
        {:ok, ver_moneda: String.trim(money_str)}
    end
  end
end
