# Chaos, Record, and Replay

## Chaos

`Feelings.chaos` samples from an answer's probability distribution instead of always taking the
top pick, useful for simulations and load-testing prompts.

```ruby
Feelings.chaos { Feelings(email).most_like(KINDS) }
```

Inside a `chaos` block, every noul and choice question draws a random number and uses it to
sample rather than always picking the highest-probability outcome.

### Sampling rules: maybe band first, then sample

A chaos draw is checked against the maybe band before any sampling happens. If a probability
falls inside a maybe band (declared via a `maybe` branch or `at_least:`, per
[Asking Questions](asking.md)), the result is `"maybe"` regardless of the draw; a probability
inside the band never gets sampled into yes or no. Outside the band, a noul question samples:
`yes` wins when the draw is less than the probability, `no` otherwise. A choice question without
a confidence gate samples across the whole probability spread using `Feelings::Distribution.sample`,
which walks the normalized cumulative probabilities and returns the first label whose cumulative
share exceeds the draw.

### Feelings.random

`Feelings.random` is the source of chaos draws, a zero-arg callable defaulting to
`-> { Kernel.rand }`. Assign your own to make chaos deterministic in tests:

```ruby
Feelings.random = -> { 0.4 }
```

## Tapes

Record a real run once, then replay it in tests without ever calling a judge again.

```ruby
tape = Feelings.record { Feelings(email).like?("spam") }
Feelings.replay(tape) { Feelings(email).like?("spam") } # judge is never called
```

### Entries and the model field

Each question asked inside a `Feelings.record` block produces one `Feelings::Tape::Entry`, with
`kind` (`"noul"` or `"choice"`), `value` (the resolved wire value), `question` (the built
wire question), `answer` (the raw answer hash, minus `draw`), `model` (the model name the judge
reported), and `draw` (the chaos draw, if any, `nil` outside a `chaos` block). `tape.entries`
returns the array; `Tape` is `Enumerable` over the same entries, so `tape.size`, `tape.count`,
and `tape.map` all work directly on the tape.

### JSON round trip

A tape round-trips through JSON:

```ruby
json = tape.to_json
restored = Feelings::Tape.from_json(json)
```

`Entry#to_h` drops any `nil` fields (so a tape recorded outside chaos serializes without a
`draw` key at all) before `to_json` generates the array.

### ReplayMismatch cases

`Feelings.replay(tape) { ... }` shifts entries off the tape's queue as questions are asked, in
order, and raises `Feelings::ReplayMismatch` in three situations:

- A question is asked but the tape has no more entries left.
- An entry's recorded `value` or `question` doesn't match what's actually being asked this time
  (the tape was recorded against different state).
- The block finishes but the tape still has unused entries left over.

During replay, the judge is never called; a judge that raises if invoked (as in the gem's own
tests) proves replay never reaches it.

### Using tapes in a test suite

Record once against a real judge, save the JSON, then load and replay it in tests so the suite
never depends on network access or nondeterministic model output:

```ruby
tape = Feelings::Tape.from_json(File.read("test/fixtures/spam_check.json"))
result = Feelings.replay(tape) { Feelings(email).like?("spam") }
```

For unit tests that don't need a prerecorded run at all, the [Stub judge](testing.md) is usually
simpler; tapes are for pinning the exact shape of a real judge's response.

Next: [Testing](testing.md).
