defmodule DigitalToken.Data do
  @moduledoc false

  # This module exists to encapsulate data
  # the is used elsewhere.

  @tokens DigitalToken.Decode.tokens_file_name()
          |> File.read!()
          |> :erlang.binary_to_term()

  def tokens do
    @tokens
  end

  @symbols DigitalToken.Decode.symbols_file_name()
           |> File.read!()
           |> :erlang.binary_to_term()

  def symbols do
    @symbols
  end

  @search_index DigitalToken.Decode.search_index(@tokens, @symbols)
  def search_index do
    @search_index
  end

  @short_names DigitalToken.Decode.short_names(@search_index)
  def short_names do
    @short_names
  end
end
