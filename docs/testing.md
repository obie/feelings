# Testing

## The Stub judge

`Feelings::Judges::Stub` answers questions from a Hash you supply, with no network call:

```ruby
Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9, kinds: :invitation)
Feelings(email).like?("spam") # => true, no network call
```

### All its forms

`Stub.new(answers = {}, model = "stub")` takes an answers hash and an optional model name
reported on every answer.

- **String key => Float**: answers a noul question whose description matches the string
  exactly. `Feelings::Judges::Stub.new("spam email" => 0.8)`.
- **Symbol key => Float**: answers a noul question whose description matches that symbol's
  registered description, or whose humanized name (`:sales_report` → `"sales report"`) matches
  when nothing is registered. `Feelings::Judges::Stub.new(spam: 0.8)`.
- **Symbol key => Symbol/String**: answers a choice question when that symbol is registered as
  a label set matching the question's criteria keys. The stub returns that label with
  confidence 1.0 and its full probability mass. `Feelings::Judges::Stub.new(kinds: :invitation)`.
- **Symbol/String key with Hash value**: for a choice question, a `Hash` value is a probability
  spread over the option labels; the stub picks the highest and reports the full spread as
  `probabilities`. `Feelings::Judges::Stub.new(kinds: { invitation: 0.3, sales_pitch: 0.7 })`.
- Any **Symbol or String value** (not a registered set name) is checked directly against the
  choice question's option keys, letting you name the winning label without registering
  anything.

An unanswerable noul or choice question raises `Feelings::JudgeError`, naming the description or
the criteria keys it couldn't match. `stub.calls` records every `{ state:, questions: }` hash
the stub was asked, in order, so you can assert on how many requests were made and what was
batched into each one.

## with_judge

`Feelings.with_judge(judge) { ... }` swaps the judge for the duration of the block only, on the
current thread, then restores whatever judge was set before:

```ruby
result = Feelings.with_judge(override_judge) { Feelings("mail").like?("spam") }
```

Useful for a one-off stub inside a test that otherwise uses `Feelings.judge =` for setup, or for
scoping a stub to a single assertion.

## Tapes in tests

A previously recorded [tape](chaos-and-tapes.md) can stand in for a live judge in tests that
need to pin an exact real-judge response shape:

```ruby
tape = Feelings::Tape.from_json(File.read("test/fixtures/some_tape.json"))
Feelings.replay(tape) { subject_under_test.call }
```

Prefer the Stub judge for ordinary unit tests; reach for a tape when you specifically want to
lock in a real judge's exact recorded output.

## reset! in setup

`feelings`'s own test suite resets state in `setup` and `teardown`:

```ruby
def setup
  Feelings.reset!
end

def teardown
  Feelings.reset!
end
```

`Feelings.reset!` clears the registry, the judge, and the random source back to their defaults,
so no state (a registered label set, a stubbed judge, a fixed random source) leaks from one test
into the next.

Next: [Judges](judges.md).
