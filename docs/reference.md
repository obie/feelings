# API Reference

## Kernel#Feelings

`Feelings(value) -> Feelings::About`

Wraps `value` and returns a `Feelings::About`. Private, available everywhere `feelings` is
required.

## Feelings (module)

| Method | Signature | Returns | Notes |
| --- | --- | --- | --- |
| `judge=` | `judge=(judge)` | judge | Sets the judge. `nil` is a valid value; questions then raise `NoJudge`. |
| `judge` | `judge` | judge | Returns the current judge, building the default `Judges::DecisionModel` around `RubyDecisionModel.client` on first call if none was set. |
| `with_judge` | `with_judge(judge) { }` | block's value | Overrides the judge for the block only, on the current thread. |
| `current_judge` | `current_judge` | judge | The thread's `with_judge` override, or `judge`. |
| `random=` | `random=(source)` | source | Sets the chaos draw source, a zero-arg callable. |
| `random` | `random` | callable | Defaults to `-> { Kernel.rand }`. |
| `load` | `load(path)` | Hash | Loads YAML at `path` into the registry; requires `"yaml"` lazily. Raises `ArgumentError` if the file's top level isn't a mapping. |
| `register` | `register(hash)` | Hash | Merges `hash` into the registry. Raises `ArgumentError` if not given a Hash. |
| `[]` | `[](key)` | String, Hash, or nil | Frozen registered value for `key`. |
| `registry` | `registry` | `Registry` | The underlying registry instance. |
| `reset!` | `reset!` | `Feelings` | Clears the registry and resets judge and random source to defaults. |
| `chaos` | `chaos { }` | block's value | Runs the block with chaos sampling enabled on the current thread. |
| `chaos?` | `chaos?` | Boolean | Whether chaos is enabled on the current thread. |
| `record` | `record { }` | `Tape` | Runs the block, recording every question asked into a new tape. |
| `current_tape` | `current_tape` | `Tape` or nil | The active recording tape, if any. |
| `replay` | `replay(tape) { }` | block's value | Answers questions from `tape` instead of the judge. Raises `ReplayMismatch` on leftover or mismatched entries. |
| `current_replay` | `current_replay` | Array or nil | The thread's active replay queue. |
| `while` | `while(initial, description, max: 5) { \|current\| }` | Object | Bounded rewrite loop. Raises `ArgumentError` if `max` is outside 1..50, `LoopLimit` if still true after `max` passes. |
| `like?` | `like?(value, *args, **kwargs)` | see `About#like?` | Shortcut for `Feelings(value).like?(...)`. |
| `like` | `like(value, *args, **kwargs, &block)` | see `About#like` | Shortcut for `Feelings(value).like(...)`. |
| `most_like` | `most_like(value, *args, **kwargs)` | see `About#most_like` | Shortcut for `Feelings(value).most_like(...)`. |
| `match` | `match(value, *args, **kwargs, &block)` | see `About#match` | Shortcut for `Feelings(value).match(...)`. |

## Feelings::About

Returned by `Feelings(value)`. Holds the value and memoizes answers per question.

| Method | Signature | Returns |
| --- | --- | --- |
| `value` | `value` | The original, unresolved object passed to `Feelings()`. |
| `like?` | `like?(arg = nil, at_least: nil, confidence: nil, **rest)` | `true`/`false`/`nil`, or a Hash of coerced values when given a Hash (batch). |
| `like` | `like(arg = nil, at_least: nil, confidence: nil, **rest, &block)` | A `Mood`, the block's dispatched value, or a Hash of `Mood`/`Pick` (batch). |
| `most_like` | `most_like(*args, confidence: nil, **rest)` | Symbol or `nil`. |
| `pick` | `pick(*args, confidence: nil, **rest)` | `Pick` or `nil`. |
| `match` | `match(labels = nil, confidence: nil, &block)` | The matching branch's value, `otherwise`'s value, or `nil`. |

`like?`/`like` given a Hash (as the sole positional arg, as keyword rest args, or both merged)
batch every entry into one judge call. See [Batching](batching.md).

## Feelings::Mood

| Method | Returns |
| --- | --- |
| `probability` | Float |
| `description` | String or Hash |
| `value` | The original value |
| `model` | String |
| `at_least` | Float or nil |
| `result` | The value returned by whichever branch ran, if any |
| `label` | `"yes"`, `"maybe"`, or `"no"` |
| `yes?` / `maybe?` / `no?` | Boolean |
| `ran?` | Boolean; whether any branch has run |
| `yes { }` / `maybe { }` / `no { }` | Registers (and, outside a `collect` block, may immediately run) that branch; returns `self` |
| `to_bool` | `true`, `false`, or `nil` for `"maybe"` |
| `to_h` | `{ label:, probability:, description:, value:, model: }` |
| `collect { \|mood\| }` | Collects branches by yielding self, then dispatches to the matching one; used internally by `About#like` |

## Feelings::Pick

| Method | Returns |
| --- | --- |
| `label` | Symbol |
| `confidence` | Float |
| `probabilities` | Hash of Symbol => Float |
| `model` | String |
| `to_h` | `{ label:, confidence:, probabilities:, model: }` |

## Feelings::Registry

| Method | Signature | Returns |
| --- | --- | --- |
| `load` | `load(path)` | merges YAML file contents; requires `"yaml"` lazily |
| `register` | `register(hash)` | merges a Hash; raises `ArgumentError` if not a Hash |
| `[]` | `[](key)` | frozen value for `key`, or `nil` |
| `to_h` | `to_h` | frozen copy of the whole registry |
| `reset!` | `reset!` | clears the registry |

## Feelings::State

| Method | Signature | Returns |
| --- | --- | --- |
| `resolve` | `resolve(object)` | Wire-safe value: `to_feelings_state` result as-is; scalar pass-through; recursively resolved Hash (string keys) or Array; `as_json` result resolved recursively; raises `UnknownState` otherwise. |

## Feelings::Questions

| Method | Signature | Returns |
| --- | --- | --- |
| `state_for` | `state_for(value)` | `{ "value" => value }` |
| `noul_instructions` | `noul_instructions(description)` | A Hash merged with a guard key if `description` is a Hash, otherwise a guarded sentence string |
| `choice_instructions` | `choice_instructions` | The fixed instruction string for choice questions |

## Feelings::Labels

| Method | Signature | Returns |
| --- | --- | --- |
| `resolve` | `resolve(labels)` | Normalizes a Symbol (registry lookup), Hash, or Array into a Symbol => description Hash. Raises `UnknownLabel` for an unregistered symbol, `BadLabels` for anything else. |
| `description_for` | `description_for(symbol)` | Registered description for `symbol`, or its humanized form. |
| `humanize` | `humanize(symbol)` | Underscores replaced with spaces. |
| `validate!` | `validate!(labels)` | Returns `labels` if valid; raises `BadLabels` if not a 2..255-entry Hash or if any description is numeric-only. |

## Feelings::MatchBuilder

Used internally by `About#match`'s block. `on(*keys, &block)` registers a branch, with an
optional trailing String as an inline description for those keys. `otherwise(&block)` sets the
fallback branch. `branch_for(label)` finds the branch whose keys include `label`.

## Feelings::Tape

| Method | Signature | Returns |
| --- | --- | --- |
| `new` | `new(entries = [])` | new Tape |
| `<<` | `<<(entry)` | appends an `Entry`, returns self |
| `each` | `each(&block)` | iterates entries (Enumerable) |
| `size` | `size` | entry count |
| `to_a` | `to_a` | Array of entry hashes (`nil` fields dropped) |
| `to_json` | `to_json(*args)` | JSON string of `to_a` |
| `Tape.from_json` | `from_json(json)` | new Tape from a JSON array; raises `ArgumentError` if not an array |

`Tape::Entry` is a `Struct` with `kind, value, question, answer, model, draw` (keyword_init).

## Feelings::Engine

Internal machinery module shared by every construct.

| Method | Signature | Returns |
| --- | --- | --- |
| `call` | `call(value:, specs:)` | Hash of id => outcome; builds questions, calls (or replays) the judge, classifies answers, records to the active tape |
| `build_question` | `build_question(spec)` | A `RubyDecisionModel::Questions.noul`/`.choice` question |
| `classify` | `classify(probability, at_least: nil, banded: false, draw: nil)` | `"yes"`, `"maybe"`, or `"no"` per the rules in [Asking Questions](asking.md) |

## Feelings::Distribution

| Method | Signature | Returns |
| --- | --- | --- |
| `normalize` | `normalize(probabilities)` | Hash of Float probabilities summing to 1.0. Raises `InvalidDistribution` if empty or if the sum is off by more than 0.02 (an all-zero spread is treated as uniform). |
| `sample` | `sample(probabilities, draw)` | The key whose cumulative normalized probability first exceeds `draw`. |

## Feelings::Judges::Stub

`new(answers = {}, model = "stub")`. See [Testing](testing.md) for every answer-hash form.
`call(state:, questions:)` answers from `answers`; raises `JudgeError` for an unanswerable
question. `calls` returns every `{ state:, questions: }` hash asked so far.

## Feelings::Judges::DecisionModel

`new(client)` wraps a `RubyDecisionModel::Client`. `call(state:, questions:)` delegates to
`client.ask` and adapts the response; re-raises any `RubyDecisionModel::Error` as `JudgeError`.

## Feelings::Railtie

Loaded automatically when `Rails::Railtie` is defined. After Rails initializes, loads
`config/feelings.yml` if it exists.

## Core extension (`feelings/core_ext`)

Requiring `feelings/core_ext` adds to `Object`: `feels_like?(...)`, `feels_like(...)`, and
`feels_most_like(...)`, each delegating to the same method on `Feelings(self)`.

## Errors

| Error | Raised when |
| --- | --- |
| `Feelings::Error` | Base class for every error below. |
| `Feelings::NoJudge` | A question is asked with `Feelings.judge` set to `nil`. |
| `Feelings::JudgeError` | A judge returns no answer for a question id, or (for `Judges::DecisionModel`) the underlying `RubyDecisionModel::Client` raises a `RubyDecisionModel::Error`, or (for `Judges::Stub`) no configured answer matches the question asked. |
| `Feelings::LoopLimit` | `Feelings.while` still evaluates true after `max` iterations. |
| `Feelings::ReplayMismatch` | During `Feelings.replay`: a question is asked with no tape entries left, a tape entry's `value`/`question` doesn't match what's being asked, or entries remain unused after the block finishes. |
| `Feelings::InvalidDistribution` | `Distribution.normalize` is given an empty probabilities Hash, or one that sums to more than 0.02 away from 1.0. |
| `Feelings::UnknownLabel` | `Labels.resolve` is given a Symbol with no registered label set. |
| `Feelings::BadLabels` | A label set has fewer than 2 or more than 255 entries, has a numeric-only description, or `most_like`/`pick` is given an argument that isn't a Symbol or Hash. |
| `Feelings::UnknownState` | `State.resolve` is given an object with no `to_feelings_state`, no `as_json`, and no other supported shape. |

Back to [Documentation](README.md).
