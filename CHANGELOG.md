# Changelog

## 0.1.0

- A `maybe` branch inside a `like` block turns the 0.3 / 0.7 bands on by branch
  registration; no source introspection.
- Chaos checks the uncertain band first and samples only outside it.
- `like` and `like?` take `confidence:` explicitly so it is never read as a question.
- Answers are memoized per question, so a second floor on the same question never re-judges.
- The numeric-only lint checks label descriptions.
- The Stub judge answers choices for inline label sets.
- `Feelings.while` defaults to 5 passes.
- Depends on the published `ruby_decision_model` 0.1.0. Published through trusted publishing.

## 0.0.1

- Initial release. `Feelings(value).like?`, `.like`, `.most_like`, `.pick`, and `.match` for
  probabilistic conditionals backed by a decision model. YAML-backed label registry, hash
  batching into a single request, `Feelings.while` for bounded loops, `Feelings.chaos` for
  distribution sampling, and `Feelings.record` / `Feelings.replay` for tapes. Default judge is
  `RubyDecisionModel.client`; ships with a `Feelings::Judges::Stub` for tests and an optional
  Rails railtie.
