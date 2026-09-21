defmodule DigitalTokenTest do
  use ExUnit.Case
  doctest DigitalToken

  @type_rank %{native: 0, auxiliary: 1, distributed: 2, fungible: 3}

  describe "resolving a name shared by several tokens" do
    test "well-known short names resolve to the canonical token" do
      assert DigitalToken.long_name("ETH") == {:ok, "Ethereum Ether"}
      assert DigitalToken.long_name("BCH") == {:ok, "Bitcoin Cash"}
      assert DigitalToken.long_name("EOS") == {:ok, "EOS"}
      assert DigitalToken.long_name("USDT") == {:ok, "Tether"}
      assert DigitalToken.long_name("DAI") == {:ok, "Dai Stablecoin"}
      assert DigitalToken.long_name("ONT") == {:ok, "Ontology"}
    end

    test "the resolved token carries the curated symbol" do
      assert DigitalToken.symbol("ETH", 1) == {:ok, "Ξ"}
      assert DigitalToken.symbol("BCH", 1) == {:ok, "Ƀ"}
      assert DigitalToken.symbol("EOS", 1) == {:ok, "ε"}
    end

    test "search/1 returns every token carrying the name, winner first" do
      results = DigitalToken.search("ONT")
      assert length(results) == 6

      assert {:ok, token_id} = DigitalToken.validate_token("ONT")
      assert {^token_id, :auxiliary} = hd(results)
    end

    test "search/1 orders by type, then curated symbol, then token identifier" do
      ranks = DigitalToken.search("ETH") |> Enum.map(&Map.fetch!(@type_rank, elem(&1, 1)))
      assert ranks == Enum.sort(ranks)

      [{first, :native} | rest] = DigitalToken.search("ETH", :native)
      assert first == "X9J9K872S"
      assert Map.has_key?(DigitalToken.symbols(), first)

      rest_ids = Enum.map(rest, &elem(&1, 0))
      assert rest_ids == Enum.sort(rest_ids)
    end

    test "short_names/0 agrees with search/2 for every name and type" do
      for {{name, dti_type}, token_id} <- DigitalToken.short_names() do
        assert [{^token_id, ^dti_type} | _rest] = DigitalToken.search(name, dti_type)
      end
    end

    test ":dti_type restricts resolution to one token type" do
      assert DigitalToken.validate_token("ONT", dti_type: :fungible) == {:ok, "G7LQ0V9FF"}

      assert DigitalToken.validate_token("BTC", dti_type: :distributed) ==
               {:error, {DigitalToken.UnknownTokenError, "BTC"}}
    end
  end

  describe "invalid input" do
    test "returns an error rather than raising" do
      for bad <- [nil, "", :"", 1, 1.5, %{}, [], {}, String.duplicate("x", 10_000)] do
        assert {:error, {DigitalToken.UnknownTokenError, ^bad}} = DigitalToken.validate_token(bad)
        assert {:error, _reason} = DigitalToken.get_token(bad)
        assert {:error, _reason} = DigitalToken.short_name(bad)
        assert {:error, _reason} = DigitalToken.long_name(bad)
        assert {:error, _reason} = DigitalToken.symbol(bad, 1)
        assert {:error, _reason} = DigitalToken.symbol(bad, 2)
        assert {:error, _reason} = DigitalToken.symbol(bad, 3)
        assert DigitalToken.search(to_string(:erlang.phash2(bad))) == []
      end
    end

    test "an unknown :dti_type is an error, not a crash" do
      assert {:error, _reason} = DigitalToken.validate_token("BTC", dti_type: :bogus)
      assert {:error, _reason} = DigitalToken.validate_token("BTC", dti_type: "native")
      assert {:error, _reason} = DigitalToken.validate_token("BTC", dti_type: :"")
    end
  end
end
