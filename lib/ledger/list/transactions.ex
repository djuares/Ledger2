defmodule Ledger.Transactions do
  def list(input_file, origin_account, destinate_account, output_file) do
    with {:ok, content} <- File.read(input_file),
         processed_content <- process_content(content, origin_account, destinate_account),
         {:ok, result} <- write_output_file(output_file, processed_content) do
      {:ok, result}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp process_content(content, "0", "0") do
    content
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")

  end
  defp process_content(content, "0", destinate_account) do
    content
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.filter(fn line ->
      parts = String.split(line, ";")
      Enum.at(parts, 6) == destinate_account
    end)
    |> Enum.join("\n")
  end

  defp process_content(content, origin_account, "0") do
    content
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.filter(fn line ->
      parts = String.split(line, ";")
      Enum.at(parts, 5) == origin_account
    end)
    |> Enum.join("\n")
  end

  defp process_content(content, origin_account, destinate_account) do
    content
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.filter(fn line ->
      parts = String.split(line, ";")
      Enum.at(parts, 5) == origin_account && Enum.at(parts, 6) == destinate_account
    end)
    |> Enum.join("\n")
  end



  defp write_output_file(output_file, content) do
    case File.write(output_file, content) do
      :ok ->
        IO.puts("Archivo guardado: #{output_file}")
        {:ok, content}

      {:error, error} ->
        {:error, "Error al escribir: #{:file.format_error(error)}"}
    end
  end
end
