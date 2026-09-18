# Changelog

## 0.0.1

- Initial release. `Feelings(value).like?`, `.like`, `.most_like`, `.pick`, and `.match` for
  probabilistic conditionals backed by a decision model. YAML-backed label registry, hash
  batching into a single request, `Feelings.while` for bounded loops, `Feelings.chaos` for
  distribution sampling, and `Feelings.record` / `Feelings.replay` for tapes. Default judge is
  `RubyDecisionModel.client`; ships with a `Feelings::Judges::Stub` for tests and an optional
  Rails railtie.
