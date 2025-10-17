defmodule Ledger.MoneyTest do
  use Ledger.RepoCase
  alias Ledger.{Money, Repo}

  import Ecto.Changeset

  # Helper para mapear errores del changeset a un formato legible
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  describe "validaciones de Money" do
    test "valida que todos los campos sean obligatorios" do
      changeset = Money.changeset(%Money{}, %{})
      refute changeset.valid?
      assert %{name: ["dato incompleto"], price: ["dato incompleto"]}= errors_on(changeset)
    end

    test "valida que el precio no puede ser negativo" do
      changeset = Money.changeset(%Money{}, %{name: "USDT", price: -1.0})
      refute changeset.valid?
      assert "El precio debe ser mayor o igual a 0" in errors_on(changeset).price
    end

    test "valida que el nombre se guarda en mayúsculas y con longitud correcta" do
      changeset = Money.changeset(%Money{}, %{name: "usdt", price: 1.0})
      assert changeset.valid?
      assert get_change(changeset, :name) == "USDT"
    end

    test "rechaza nombres con menos de 3 o más de 4 letras" do
      short = Money.changeset(%Money{}, %{name: "US", price: 1.0})
      long = Money.changeset(%Money{}, %{name: "PESOS", price: 1.0})

      refute short.valid?
      refute long.valid?
    end

    test "valida que el nombre sea único" do
      {:ok, _} =
        %Money{}
        |> Money.changeset(%{name: "USDT", price: 1.0})
        |> Repo.insert()

      {:error, changeset} =
        %Money{}
        |> Money.changeset(%{name: "usdt", price: 1.5})
        |> Repo.insert()

      assert  "Ya existe una moneda con ese nombre" in errors_on(changeset).name
    end

    test "id es único (primary key autogenerado)" do
      {:ok, usd} =
        %Money{}
        |> Money.changeset(%{name: "USDT", price: 1.0})
        |> Repo.insert()

      {:ok, eur} =
        %Money{}
        |> Money.changeset(%{name: "EURS", price: 2.0})
        |> Repo.insert()

      assert usd.id != eur.id
    end
  end

end
