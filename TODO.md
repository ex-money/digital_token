# TODO

Work on `digital_token`. Design notes, when there are any, live in `plans/`.

## In progress

* [ ] **Publish 2.1.1** — fixes starting on OTP 26: the `json_polyfill` dependency, added only when compiled on OTP 26 and so missing from the hex metadata, is removed. Not yet published.

## Done

* [x] **Publish 2.1.0** — deterministic name resolution, re-keyed symbols, CI workflow. 2026-09-21, v2.1.0.

* [x] **Reply to and close issues #3 and #5** — #3 out of scope by design, #5 fixed by deterministic name resolution. 2026-09-21.

* [x] **Deterministic short name resolution** — ambiguous names resolve by type, curated symbol, then token identifier on every OTP release; `search/1` returns candidates winner first. 2026-09-21.

* [x] **Tests for ambiguous names and invalid input** — pins ETH, BCH, EOS, USDT, DAI and ONT to their canonical tokens and checks every lookup returns an error on garbage. 2026-09-21.

* [x] **Add the standard CI workflow** — Elixir 1.17–1.20 across OTP 26–29; the 1.20 rows moved from 1.20.2 to 1.20.4. 2026-09-21.
