# Changelog

## Digital Token 2.1.0

This is the changelog for Digital Token version 2.1.0 released on September 21st, 2026.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Bug Fixes

* Short name and long name lookups resolve the same token on every OTP release. An ambiguous name resolves by token type (native first), then curated symbol, then ascending token identifier, and `DigitalToken.search/1` returns the candidates in that order, winner first.

* `DigitalToken.symbol/2` returns the curated symbol for `ETH`, `BCH` and `EOS` again. The bundled symbol data is regenerated and keyed to Ethereum Ether, Bitcoin Cash and EOS rather than to layer-two deployments of them.

### Enhancements

* Adds the standard GitHub Actions CI workflow (Elixir 1.17–1.20 across OTP 26–29, with formatting and dialyzer on the lint row).

* `DigitalToken.validate_token/2` and `DigitalToken.get_token/1` document how an ambiguous name resolves, and the README gains a section on ambiguous short names.

## Digital Token 2.0.0

This is the changelog for Digital Token version 2.0.0 released on April 24th, 2026.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Breaking Changes

* dtif.org has moved to a paywall model requiring several thousand euros a year to access the full registry data. Fortunately they do maintain a publically available extract which is enough to support this library. However even that data is not accessible programmatically. Therefore the data is only updated when a maintainer downloads it manually.  As a result, the data is tied to the package release which is not a good long time solution. Like the Localize solution, the next release of digital_token will generate an .etf file of the content we need and store in in R2.

### Enhancements

* `DigitalToken.search/1` and `DigitalToken.search/2` return every token that carries a short name or long name, and `DigitalToken.validate_token/2` accepts a `:dti_type` option to restrict a name lookup to one token type.

## Digital Token 1.0.0

This is the changelog for Digital Token version 1.0.0 released on September 6th, 2024.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Bug Fixes

* Fix parsing error on some tokens from the updated registry.

### Enhancements

* Use the erlang `:json` module as a candidate JSON decoder if the underlying OTP release supports it (>= OTP 27).  This support also requires at least `cldr_utils` version 2.28.2.

## Digital Token 0.6.0

This is the changelog for Digital Token version 0.6.0 released on July 8th, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Bug Fixes

* Remove checking Phoenix and Ecto json_library configurations.  Ecto no longer configures its `:json_library` in `config.exs` and checking for Phoenix configuration can cause config failures when [building in Docker](https://github.com/elixir-cldr/cldr/issues/208).

* Sort the short names for a token by their length so that the standard short name is the shortest one.

* Fix code that made an implicit assumption about map order.

### Enhancements

* Update to the latest toekn registry and symbol registry.

## Digital Token 0.5.0

This is the changelog for Digital Token version 0.5.0 released on June 22nd, 2023.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Enhancements

* Make the JSON library configurable. Like `ex_cldr` it will also attempt to use the JSON library configured for `ex_cldr`, `ecto`, `phoenix` or if otherwise configured `Jason` or `Poison`.

## Digital Token 0.4.0

This is the changelog for Digital Token version 0.4.0 released on May 20th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Enhancements

* Parse and structure the downloaded digital token registry and digital token symbols at download time rather than compile time. This reduces the compile time significantly.

## Digital Token 0.3.0

This is the changelog for Digital Token version 0.3.0 released on May 14th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Enhancements

* Add `DigitalToken.short_name/1` to return the short name of the digital token. This is analogous to the currency code for a currency.

* Add `DigitalToken.long_name/1` to return the long name of the digital token. This is analogous to the name of a currency.

* Add `DigitalToken.symbol/2` to return a "currency" symbol for a digital token that will be used for number formatting in [ex_cldr_numbers](https://github.com/elixir-cldr/cldr_numbers) and [ex_money](https://github.com/kipcole9/money).

## Digital Token 0.2.0

This is the changelog for Digital Token version 0.2.0 released on May 9th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Bug Fixes

* Return only the token id from `DigitalToken.validate_token/1` when the argument is already a valid token identifier.

## Digital Token 0.1.0

This is the changelog for Digital Token version 0.1.0 released on May 8th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/digital_token/tags)

### Enhancements

* Initial release
