defmodule Mix.Tasks.DigitalToken.Symbols.Update do
  @moduledoc """
  Updates the digital token symbols data.

  Data is copied from [Crypto Currency Symbols](https://github.com/yonilevy/crypto-currency-symbols).

  ## Usage

      mix digital_token.symbols.update [path_to_json]

  If no path is given, fetches from the GitHub source URL.

  The task decodes JSON with OTP's `:json` module, so it needs
  OTP 27 or later.

  """

  use Mix.Task
  require Logger

  @shortdoc "Update digital token symbol data"

  @url "https://raw.githubusercontent.com/yonilevy/crypto-currency-symbols/master/symbols.json"

  @symbols_file_name DigitalToken.Decode.symbols_file_name()

  @doc false
  def run(args) do
    if Code.ensure_loaded?(:json) do
      update(args)
    else
      Mix.raise("mix digital_token.symbols.update needs OTP 27 or later for the :json module")
    end
  end

  defp update(args) do
    case args do
      [path] ->
        update_from_file(path)

      [] ->
        update_from_url()
    end
  end

  defp update_from_file(path) do
    Logger.info("Reading digital token symbols from #{path}")

    body = File.read!(path)

    symbols =
      body
      |> DigitalToken.Decode.decode_symbols()
      |> :erlang.term_to_binary()

    File.write!(@symbols_file_name, symbols)
    Logger.info("Updated digital token symbols at #{@symbols_file_name}")
  end

  defp update_from_url do
    :inets.start()
    :ssl.start()

    url = String.to_charlist(@url)
    request = {url, []}
    http_options = [ssl: [{:verify, :verify_none}], timeout: 30000]
    options = [body_format: :binary]

    Logger.info("Fetching digital token symbols from #{@url}")

    case :httpc.request(:get, request, http_options, options) do
      {:ok, {{_, 200, _}, _response_headers, body}} ->
        Logger.info("Successfully retrieved digital token symbols")

        symbols =
          body
          |> DigitalToken.Decode.decode_symbols()
          |> :erlang.term_to_binary()

        File.write!(@symbols_file_name, symbols)
        Logger.info("Updated digital token symbols at #{@symbols_file_name}")

      {:ok, {{_, status, _}, _headers, body}} ->
        Logger.warning("Failed to update digital token symbols. HTTP #{status}: #{body}")

      {:error, reason} ->
        Logger.warning("Failed to update digital token symbols. #{inspect(reason)}")
    end
  end
end
