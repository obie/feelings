# Batching

Any `like?` or `like` call given a `Hash` asks everything it names in one request.

```ruby
Feelings(email).like?(spam: "spam", urgent: :urgent, kind: :kinds)
# => { spam: false, urgent: true, kind: :invitation }
```

`like` on the same hash returns `Mood` and `Pick` objects instead of coerced values:

```ruby
result = Feelings(email).like(spam: "spam email", kind: :kinds)
result[:spam] # a Mood
result[:kind] # a Pick
```

## What a String vs Hash/Array vs Symbol value means

Each value in the batch hash decides what kind of question its key asks:

- A **String** value is a noul (yes/no) question, using that string as the description.
- A **Hash** or **Array** value is a choice question: the value is resolved as a label set the
  same way `most_like`/`pick` resolve one, and the key gets back a label.
- A **Symbol** value looks the key up in the registry. If the registered value is itself a
  `Hash`, it's a choice question over that label set. If it's a `String` (or unregistered), it's
  a noul question using that string, or the humanized symbol if nothing is registered.

`like?` coerces the batch's results to plain values: a `Mood` becomes its `to_bool`, a `Pick`
becomes its `label`. `like` leaves the `Mood`/`Pick` objects intact.

## One request per call

Every question in a batch hash is sent to the judge in a single `judge.call`, regardless of how
many keys it has. This is the entire point of the hash form: instead of one round trip per
question, everything you name goes out together.

## How at_least:/confidence: apply across the batch

A single `at_least:` and a single `confidence:` keyword can be passed alongside the hash, and
each applies to every noul or choice question in the batch respectively; there's no way to set
a different threshold per key within one batched call. `confidence:` is always read as a
keyword, never as a question key, even inside the same call that batches other keys.

```ruby
Feelings(email).like?(spam: "spam", kind: :kinds, confidence: 0.5)
```

## Why batching matters

Batched questions are evaluated by the judge in one request rather than one round trip per
question, so several judgments about the same value cost one network call instead of many. Cost
is measured in tokens, not requests, so batching doesn't reduce token spend by itself, it
reduces latency and the number of separate calls.

Next: [Feelings.while](loops.md).
