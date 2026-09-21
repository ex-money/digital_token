# TODO

Work on `digital_token`. Design notes, when there are any, live in `plans/`.

## Open

* [ ] **Publish 2.1.0** — release review passed on 2026-09-21; commit the review fixes, tag `v2.1.0`, run `mix hex.publish`.

## Done

* [x] **Reply to and close issues #3 and #5** — #3 out of scope by design, #5 fixed by deterministic name resolution. 2026-09-21.

* [x] **Deterministic short name resolution** — ambiguous names resolve by type, curated symbol, then token identifier on every OTP release; `search/1` returns candidates winner first. 2026-09-21.

* [x] **Tests for ambiguous names and invalid input** — pins ETH, BCH, EOS, USDT, DAI and ONT to their canonical tokens and checks every lookup returns an error on garbage. 2026-09-21.

* [x] **Add the standard CI workflow** — Elixir 1.17–1.20 across OTP 26–29; the 1.20 rows moved from 1.20.2 to 1.20.4. 2026-09-21.
