defmodule DigitalToken do
  @moduledoc """
  Functions to validate, search and retrieve digital token
  data sourced from the [DTIF registry](https://dtif.org).

  A token is identified by its nine character token identifier
  (DTI), which is unique. Short names such as "BTC" and long
  names such as "Bitcoin" are informative and are not unique:
  the same short name is carried by native tokens on several
  chains, by wrapped tokens and by fungible token groups.
  `validate_token/2`, `get_token/1` and the other functions that
  accept a name resolve it to one token with a documented, stable
  precedence; `search/1` and `search/2` return every token that
  carries a name so a caller can choose.

  """

  @token_types [:native, :auxiliary, :distributed, :fungible]

  defstruct header: nil,
            informative: nil,
            metadata: nil,
            normative: nil

  @typedoc """
  The structure of data matching that hosted in
  the [DTIF registry](https://dtif.org)/

  """
  @type t :: %__MODULE__{
          header: map(),
          informative: map(),
          metadata: map(),
          normative: map()
        }

  @typedoc """
  token_id is a random 9-character
  string defined by the [dtif registry](https://dtif.org)
  that uniquely identifies a digital token.

  """
  @type token_id :: String.t()

  @typedoc """
  The type of a token
  """
  @type token_type :: :native | :auxiliary | :distributed | :fungible

  @typedoc """
  A digital token may have zero or more short
  names associated with it. They are arbitrary
  strings, usually three or four characters in
  length. For example "BTC", "ETH" and "DOGE".

  """
  @type short_name :: String.t()

  @typedoc """
  A mapping of digital token identifiers
  to the registry data for that token.

  """
  @type token_map :: %{
          token_id() => t()
        }

  @typedoc """
  A mapping from a short name or long name,
  paired with a token type, to the token identifier
  that name resolves to for that type.

  """
  @type short_name_map :: %{
          {short_name(), token_type} => token_id()
        }

  @typedoc """
  A mapping of digital token identifiers
  to a currency symbol for that token.

  """
  @type symbol_map :: %{
          token_id() => String.t()
        }

  defguard is_digital_token(token_id) when is_binary(token_id) and byte_size(token_id) == 9

  @doc """
  Returns a map of the digital tokens in the
  [dtif registry](https://dtif.org).

  """
  @spec tokens :: token_map()
  def tokens do
    DigitalToken.Data.tokens()
  end

  @doc """
  Returns a mapping of digital token short
  names to digital token identifiers.

  """
  @spec short_names :: short_name_map()
  def short_names do
    DigitalToken.Data.short_names()
  end

  @doc """
  Returns a mapping of digital token identifiers
  names to a currency symbol.

  """
  @spec symbols :: symbol_map()
  def symbols do
    DigitalToken.Data.symbols()
  end

  @doc """
  Returns every token that carries the given short name or long name.

  Many tokens share a short name. "ETH", for example, names a native
  token on Ethereum and on each of its layer-two chains, wrapped tokens
  on other chains, and fungible token groups. This function returns all
  of them so a caller can choose.

  ## Arguments

  * `name` is a short name (e.g. `"BTC"`) or long name (e.g. `"Bitcoin"`).

  ## Returns

  * A list of `{token_id, dti_type}` tuples in resolution order, or an
    empty list if no tokens match. The first entry is the token that
    `validate_token/2` and `get_token/1` resolve the name to. The order
    is native before auxiliary before distributed before fungible and,
    within a type, tokens with a curated symbol before those without,
    then ascending token identifier.

  ## Examples

      iex> DigitalToken.search("Bitcoin") |> hd()
      {"4H95J0R2X", :native}

      iex> DigitalToken.search("ONT")
      [
        {"7Z13NV2QM", :auxiliary},
        {"R9LRZNL89", :auxiliary},
        {"WS6SFQ5D1", :auxiliary},
        {"G7LQ0V9FF", :fungible},
        {"HJVWQ4S40", :fungible},
        {"M2W3DQB67", :fungible}
      ]

      iex> DigitalToken.search("Nothing")
      []

  """
  @spec search(String.t()) :: [{token_id(), token_type()}]
  def search(name) when is_binary(name) do
    Map.get(DigitalToken.Data.search_index(), name, [])
  end

  @doc """
  Returns every token of one type that carries the given short name
  or long name.

  This narrows the result of `search/1` when a short name like `"ETH"`
  maps to many tokens across different types.

  ## Arguments

  * `name` is a short name (e.g. `"BTC"`) or long name (e.g. `"Bitcoin"`).

  * `dti_type` is one of `:native`, `:auxiliary`, `:distributed`, or `:fungible`.

  ## Returns

  * A list of `{token_id, dti_type}` tuples matching both the name and
    the type, in the same order as `search/1`, or an empty list if no
    tokens match.

  ## Examples

      iex> DigitalToken.search("ETH", :native) |> hd()
      {"X9J9K872S", :native}

      iex> DigitalToken.search("BTC", :native)
      [{"4H95J0R2X", :native}]

      iex> DigitalToken.search("ONT", :fungible)
      [{"G7LQ0V9FF", :fungible}, {"HJVWQ4S40", :fungible}, {"M2W3DQB67", :fungible}]

      iex> DigitalToken.search("Nothing", :native)
      []

  """
  @spec search(String.t(), token_type()) :: [{token_id(), token_type()}]
  def search(name, dti_type) when is_binary(name) and dti_type in @token_types do
    name
    |> search()
    |> Enum.filter(fn {_id, type} -> type == dti_type end)
  end

  @doc """
  Validates a token identifier or short name
  and returns the token identifier or an error.

  ## Arguments

  * `id` is any token identifier or short name.

  * `options` is a keyword list of options.

  ## Options

  * `:dti_type` restricts a short name or long name lookup to one
    token type: `:native`, `:auxiliary`, `:distributed` or `:fungible`.

  ## Returns

  * `{:ok, token_id}` or

  * `{:error, {exception, id}}`

  ## Resolving ambiguous names

  Short names and long names are not unique in the registry. "ETH",
  for example, names a dozen native tokens (Ethereum Ether and one per
  layer-two chain) as well as many wrapped and fungible tokens. When
  `id` is not a token identifier, the first entry returned by
  `search/1` (or by `search/2` when `:dti_type` is given) wins. That
  order is native before auxiliary before distributed before fungible
  and, within a type, tokens with a curated symbol before those
  without, then ascending token identifier. It depends only on the
  registry data, so the same name resolves to the same token on every
  OTP release. Callers that need a specific token should pass the
  token identifier, or choose one from `search/1`.

  ## Examples

      iex> DigitalToken.validate_token("BTC")
      {:ok, "4H95J0R2X"}

      iex> DigitalToken.validate_token("Bitcoin")
      {:ok, "4H95J0R2X"}

      iex> DigitalToken.validate_token "4H95J0R2X"
      {:ok, "4H95J0R2X"}

      iex> DigitalToken.validate_token("ONT")
      {:ok, "7Z13NV2QM"}

      iex> DigitalToken.validate_token("ONT", dti_type: :fungible)
      {:ok, "G7LQ0V9FF"}

      iex> DigitalToken.validate_token("BTC", dti_type: :distributed)
      {:error, {DigitalToken.UnknownTokenError, "BTC"}}

      iex> DigitalToken.validate_token("Nothing")
      {:error, {DigitalToken.UnknownTokenError, "Nothing"}}

  """
  @spec validate_token(token_id() | short_name(), Keyword.t()) ::
          {:ok, token_id()} | {:error, {module(), any()}}
  def validate_token(id, options \\ []) do
    if Map.has_key?(tokens(), id) do
      {:ok, id}
    else
      case candidates(id, Keyword.get(options, :dti_type)) do
        [{token_id, _dti_type} | _rest] -> {:ok, token_id}
        [] -> {:error, unknown_token_error(id)}
      end
    end
  end

  defp candidates(name, nil) when is_binary(name) do
    search(name)
  end

  defp candidates(name, dti_type) when is_binary(name) and dti_type in @token_types do
    search(name, dti_type)
  end

  defp candidates(_name, _dti_type) do
    []
  end

  @doc """
  Returns the short name of a digital token.

  ## Arguments

  * `token_id` is any valid digital token identifier.

  ## Returns

  * `{:ok, short_name}` where `short_name` is either
    the first short name in `token.informative.short_names` or
    the token long name if there are no short names.

  * `{:error, {exception, reason}}`

  ## Examples

      iex> DigitalToken.short_name "BTC"
      {:ok, "BTC"}

      iex> DigitalToken.short_name "4H95J0R2X"
      {:ok, "BTC"}

      iex> DigitalToken.short_name "TV5T68SZJ"
      {:ok, "LUNC"}

  """
  @spec short_name(token_id) :: {:ok, String.t()} | {:error, {module(), String.t()}}
  def short_name(token_id) do
    with {:ok, token} <- get_token(token_id) do
      case Map.get(token.informative, :short_names) do
        [first | _rest] -> {:ok, first}
        _other -> {:ok, token.informative.long_name}
      end
    end
  end

  @doc """
  Returns the long name of a digital token.

  ## Arguments

  * `token_id` is any valid digital token identifier.

  ## Returns

  * `{:ok, long_name}` where `long_name` is the token's
    registered name.

  * `{:error, {exception, reason}}`

  ## Examples

      iex> DigitalToken.long_name "BTC"
      {:ok, "Bitcoin"}

      iex> DigitalToken.long_name "4H95J0R2X"
      {:ok, "Bitcoin"}

      iex> DigitalToken.long_name "TV5T68SZJ"
      {:ok, "Terra Classic"}

  """
  @spec long_name(token_id) :: {:ok, String.t()} | {:error, {module(), String.t()}}
  def long_name(token_id) do
    with {:ok, token} <- get_token(token_id) do
      Map.fetch(token.informative, :long_name)
    end
  end

  @doc """
  Returns a currency symbol used in number formatting.

  ## Arguments

  * `token_id` is any valid digital token identifier.

  * `style` is a number in the range `1` to `4` as follows:
      * `1` is the token's symbol, if it exists
      * `2` is the token's short name as a proxy for a currency code
      * `3` is the token's long name
      * `4` is the token's symbol as a proxy for a narrow currency symbol

  ## Returns

  * `{:ok, symbol}` or

  * `{:error, {exception, reason}}`

  ## Examples

      iex> DigitalToken.symbol "BTC", 1
      {:ok, "₿"}

      iex> DigitalToken.symbol "BTC", 2
      {:ok, "BTC"}

      iex> DigitalToken.symbol "BTC", 3
      {:ok, "Bitcoin"}

      iex> DigitalToken.symbol "BTC", 4
      {:ok, "₿"}

      iex> DigitalToken.symbol "ETH", 4
      {:ok, "Ξ"}

      iex> DigitalToken.symbol "DOGE", 4
      {:ok, "Ð"}

      iex> DigitalToken.symbol "DODGY", 4
      {:error, {DigitalToken.UnknownTokenError, "DODGY"}}

  """
  @spec symbol(token_id, 1..4) :: {:ok, String.t()} | {:error, {module(), String.t()}}
  def symbol(token_id, style) when style in [1, 4] do
    with {:ok, token_id} <- validate_token(token_id),
         {:ok, symbol} <- Map.fetch(symbols(), token_id) do
      {:ok, symbol}
    else
      :error -> short_name(token_id)
      other_error -> other_error
    end
  end

  def symbol(token_id, 2) do
    short_name(token_id)
  end

  def symbol(token_id, 3) do
    long_name(token_id)
  end

  @doc """
  Returns the registry data for a given token
  identifier.

  ## Arguments

  * `id` is any token identifier, short name or long name. A name
    that several tokens carry resolves as described in
    `validate_token/2`; use `search/1` to see every candidate.

  ## Returns

  * `{:ok, registry_data}` or

  * `{:error, {exception, id}}`

  ## Example

      DigitalToken.get_token("BTC")
      #=> {:ok,
       %DigitalToken{
         header: %{
           dlt_type: :blockchain,
           dti: "4H95J0R2X",
           dti_type: :native,
           template_version: #Version<1.0.0>
         },
         informative: %{
           long_name: "Bitcoin",
           public_distributed_ledger_indication: false,
           short_names: ["BTC", "XBT"],
           unit_multiplier: 100000000,
           url: "https://github.com/bitcoin/bitcoin"
         },
         metadata: %{
           .....

  """
  @spec get_token(token_id() | short_name()) :: {:ok, t()} | {:error, {module(), any()}}
  def get_token(id) do
    with {:ok, token} <- validate_token(id) do
      {:ok, Map.fetch!(tokens(), token)}
    end
  end

  @doc """
  Returns the registry data for a given token
  identifier.

  ## Arguments

  * `id` is any token identifier or short name

  ## Returns

  * `registry_data` or

  * raises an exception

  ## Example

      DigitalToken.get_token("BTC")
      #=> %DigitalToken{
         header: %{
           dlt_type: :blockchain,
           dti: "4H95J0R2X",
           dti_type: :native,
           template_version: #Version<1.0.0>
         },
         informative: %{
           long_name: "Bitcoin",
           public_distributed_ledger_indication: false,
           short_names: ["BTC", "XBT"],
           unit_multiplier: 100000000,
           url: "https://github.com/bitcoin/bitcoin"
         },
         metadata: %{
           .....

  """
  @spec get_token!(token_id() | short_name()) :: t() | no_return()
  def get_token!(id) do
    case get_token(id) do
      {:ok, token} -> token
      {:error, {exception, id}} -> raise exception, id
    end
  end

  defp unknown_token_error(id) do
    {DigitalToken.UnknownTokenError, id}
  end
end
