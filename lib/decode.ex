defmodule DigitalToken.Decode do
  @moduledoc false

  # This module reads the json file and formats the
  # data into a format useful for looking up registry
  # data.

  @priv_dir Application.app_dir(:digital_token, "priv")
  @tokens_file_name Path.join(@priv_dir, "digital_token_registry.etf")
  @symbols_file_name Path.join(@priv_dir, "digital_token_symbols.etf")

  @external_resource @tokens_file_name
  @external_resource @symbols_file_name

  def tokens_file_name do
    @tokens_file_name
  end

  def symbols_file_name do
    @symbols_file_name
  end

  def decode_tokens(body) do
    body
    |> json_decode!()
    |> Map.fetch!("records")
    |> Enum.filter(&has_dti?/1)
    |> Enum.map(&restructure_key/1)
    |> merge_map_list()
  end

  def decode_symbols(body) do
    body
    |> json_decode!()
    |> Enum.map(fn token ->
      symbol_name = token["symbol"]
      unicode_symbol = token["usym"]

      token_types = [:native, :auxiliary, :distributed, :fungible]

      Enum.find_value(token_types, nil, fn type ->
        if token_id = Map.get(DigitalToken.Data.short_names(), {symbol_name, type}) do
          {token_id, unicode_symbol}
        else
          nil
        end
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  defp has_dti?(%{"Header" => header}) do
    Map.has_key?(header, "DTI")
  end

  def restructure_key(map) do
    header = Map.fetch!(map, "Header")
    dti = Map.fetch!(header, "DTI")

    map =
      map
      |> normalize_keys()
      |> transform_values()
      |> structify(DigitalToken)

    %{dti => map}
  end

  @type_priority %{native: 0, auxiliary: 1, distributed: 2, fungible: 3}

  # Maps every long name and short name to the tokens that carry it,
  # as `{token_id, dti_type}` pairs in resolution order: native before
  # auxiliary before distributed before fungible and, within a type,
  # tokens with a curated symbol before those without, then ascending
  # token id. The order depends only on the data, never on map
  # traversal order, so a name resolves identically on every OTP release.

  def search_index(data, symbols) do
    data
    |> Enum.flat_map(fn {token_id, values} ->
      dti_type = Map.get(values.header, :dti_type, :native)
      for name <- names(values), do: {name, {token_id, dti_type}}
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {name, matches} ->
      {name, Enum.sort_by(matches, &resolution_order(&1, symbols))}
    end)
  end

  # Maps `{name, dti_type}` to the token that name resolves to for that
  # type: the first entry of that type in the search index.

  def short_names(search_index) do
    Enum.reduce(search_index, %{}, fn {name, matches}, acc ->
      Enum.reduce(matches, acc, fn {token_id, dti_type}, inner_acc ->
        Map.put_new(inner_acc, {name, dti_type}, token_id)
      end)
    end)
  end

  defp names(values) do
    [values.informative.long_name | values.informative.short_names]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp resolution_order({token_id, dti_type}, symbols) do
    type_rank = Map.get(@type_priority, dti_type, map_size(@type_priority))
    symbol_rank = if Map.has_key?(symbols, token_id), do: 0, else: 1
    {type_rank, symbol_rank, token_id}
  end

  defp merge_map_list(maps) do
    Enum.reduce(maps, %{}, &Map.merge(&2, &1))
  end

  # ── Key normalization ─────────────────────────────────────────

  defp normalize_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} ->
      new_key = normalize_key(key)
      {new_key, normalize_keys(value)}
    end)
    |> Map.new()
  end

  defp normalize_keys(list) when is_list(list) do
    Enum.map(list, &normalize_keys/1)
  end

  defp normalize_keys(value), do: value

  @key_map %{
    "Header" => :header,
    "Informative" => :informative,
    "Normative" => :normative,
    "Metadata" => :metadata,
    "DTI" => :dti,
    "DTIType" => :dti_type,
    "DLTType" => :dlt_type,
    "LongName" => :long_name,
    "ShortNames" => :short_names,
    "ShortName" => :short_name,
    "UnitMultiplier" => :unit_multiplier,
    "URL" => :url,
    "PublicDistributedLedgerIndication" => :public_distributed_ledger_indication,
    "BlockNumberOffset" => :block_number_offset,
    "AnchorBlockHash" => :anchor_block_hash,
    "AnchorBlockHashAlgorithm" => :anchor_block_hash_algorithm,
    "AnchorBlockUTCTimestamp" => :anchor_block_utc_timestamp,
    "AnchorBlockHeight" => :anchor_block_height,
    "AuxiliaryDistributedLedger" => :auxiliary_distributed_ledger,
    "AuxiliaryMechanism" => :auxiliary_mechanism,
    "AuxiliaryTechnicalReference" => :auxiliary_technical_reference,
    "EquivalentDigitalTokenGroupDTI" => :equivalent_digital_token_group_dti,
    "ProtocolDistributedLedger" => :protocol_distributed_ledger,
    "DTIExternalIdentifiers" => :dti_external_identifiers,
    "DigitalAssetExternalIdentifiers" => :digital_asset_external_identifiers,
    "DigitalAssetExternalIdentifierType" => :digital_asset_external_identifier_type,
    "DigitalAssetExternalIdentifierValue" => :digital_asset_external_identifier_value,
    "IssuerIdentifiers" => :issuer_identifiers,
    "MaintainerIdentifiers" => :maintainer_identifiers,
    "OrigLangLongName" => :orig_lang_long_name,
    "recVersion" => :rec_version,
    "recDateTime" => :rec_date_time,
    "templateVersion" => :template_version,
    "Provisional" => :provisional,
    "Private" => :private,
    "Disputed" => :disputed,
    "Deleted" => :deleted,
    "Certified" => :certified,
    "Issued" => :issued,
    "Lapsed" => :lapsed,
    "Retired" => :retired
  }

  defp normalize_key(key) when is_binary(key) do
    Map.get(@key_map, key, underscore(key))
  end

  defp underscore(key) do
    key
    |> String.replace(~r/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
    |> String.replace(~r/([a-z\d])([A-Z])/, "\\1_\\2")
    |> String.downcase()
    |> String.to_atom()
  end

  # ── Value transformations ─────────────────────────────────────

  defp transform_values(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value == "<locked>" end)
    |> Enum.map(fn {key, value} -> {key, transform_value(key, value)} end)
    |> Enum.reject(fn {_key, value} -> value == :locked_removed end)
    |> Map.new()
  end

  defp transform_value(:dti_type, 0), do: :auxiliary
  defp transform_value(:dti_type, 1), do: :native
  defp transform_value(:dti_type, 2), do: :distributed
  defp transform_value(:dti_type, 3), do: :fungible

  defp transform_value(:dlt_type, "0"), do: :other
  defp transform_value(:dlt_type, "1"), do: :blockchain
  defp transform_value(:dlt_type, 0), do: :other
  defp transform_value(:dlt_type, 1), do: :blockchain

  defp transform_value(:template_version, "V" <> version) do
    Version.parse!(version)
  end

  defp transform_value(:short_names, %{short_name: name}) when is_binary(name) do
    [name]
  end

  defp transform_value(:short_names, names) when is_list(names) do
    names
    |> Enum.map(fn
      %{short_name: name} -> name
      name when is_binary(name) -> name
    end)
    |> Enum.sort_by(&String.length/1)
  end

  defp transform_value(:short_names, nil), do: []

  defp transform_value(:anchor_block_utc_timestamp, datetime) when is_binary(datetime) do
    NaiveDateTime.from_iso8601!(datetime)
  end

  defp transform_value(:rec_date_time, datetime) when is_binary(datetime) do
    NaiveDateTime.from_iso8601!(datetime)
  end

  defp transform_value(:anchor_block_hash, "0x" <> hash) do
    case Integer.parse(hash, 16) do
      {integer_hash, ""} -> integer_hash
      {integer_hash, remainder} -> {integer_hash, remainder}
    end
  end

  defp transform_value(:auxiliary_technical_reference, "0x" <> hash) do
    case Integer.parse(hash, 16) do
      {integer_hash, ""} -> integer_hash
      {integer_hash, remainder} -> {integer_hash, remainder}
    end
  end

  defp transform_value(:unit_multiplier, value) when is_integer(value), do: value

  defp transform_value(_key, value) when is_map(value) do
    transform_values(value)
  end

  defp transform_value(_key, value) when is_list(value) do
    Enum.map(value, fn
      item when is_map(item) -> transform_values(item)
      item -> item
    end)
  end

  defp transform_value(_key, value), do: value

  defp structify(map, struct) do
    struct(struct, map)
  end

  defp json_decode!(binary) do
    :json.decode(binary)
  end
end
