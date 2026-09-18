# feelings

A decision model can answer a typed question about a value with a calibrated probability.
[Probably](https://probably-lang.southpolesteve.workers.dev/) showed what code reads like when
an `if` can ask one of those questions directly instead of hand-rolling a prompt. `feelings`
brings that construct, `feels`, to Ruby. Inspired by Probably.

It works with Jev through OpenRouter or Typesafe's API via
[ruby_decision_model](https://rubygems.org/gems/ruby_decision_model), the default judge.

## Install

```ruby
gem "feelings"
```

## Setup

No configuration is required beyond an API key. Set `OPENROUTER_API_KEY` or
`TYPESAFE_API_KEY` in your environment and `feelings` picks a judge automatically the first
time you ask it something.

```ruby
require "feelings"

Feelings("that email").like?("genuinely urgent")
# => true or false
```

## like? and like

`like?` asks a yes/no question about a value.

```ruby
f = Feelings(email.body)
f.like?("spam")
```

`like` returns a `Mood` you can branch on. Declare a `maybe` branch and the yes/maybe/no split
widens to 0.3/0.7 automatically, so an ambiguous answer has somewhere to go.

```ruby
f.like("full of corporate jargon") do |mood|
  mood.yes   { rewrite(draft) }
  mood.maybe { flag_for_review(draft) }
  mood.no    { draft }
end
```

Pass `at_least:` to set your own probability floor instead. `like?` then returns `nil` for the
middle zone rather than forcing a guess.

```ruby
f.like?("a security incident", at_least: 0.8) # true, false, or nil
```

## most_like

`most_like` picks the best-fitting label out of a set and hands back the winning symbol.

```ruby
KINDS = { invitation: "an invitation to an event", sales_pitch: "someone selling something" }
Feelings(email).most_like(KINDS) # => :invitation
```

Pass `confidence:` to get `nil` back instead of a shaky guess.

## YAML registry

Keep your descriptions and label sets out of the codebase and load them once.

```yaml
# config/feelings.yml
kinds:
  invitation: an invitation to an event
  sales_pitch: someone selling something
  other: anything else
spam: an unsolicited commercial email
```

```ruby
Feelings.load("config/feelings.yml")
Feelings(email).like?(:spam)        # uses the registered description
Feelings(email).most_like(:kinds)   # uses the registered label set
```

YAML loading is lazy, so plain `require "feelings"` never pulls in the YAML library. You can also
register descriptions straight from Ruby without touching a file:

```ruby
Feelings.register(spam: "an unsolicited commercial email", kinds: KINDS)
```

Every construct works fine with an empty registry and no config file. `Feelings.load` and
`Feelings.register` can both be called more than once; later calls override earlier keys.

## Hash batching

Any `like?` or `like` call given a Hash asks everything it names in one request.

```ruby
Feelings(email).like?(spam: "spam", urgent: :urgent, kind: :kinds)
# => { spam: false, urgent: true, kind: :invitation }
```

## match

`match` dispatches on the winning label with a block, inline descriptions included.

```ruby
Feelings(email).match(KINDS) do
  on(:invitation) { accept_invite(email) }
  on(:sales_pitch, :other) { archive(email) }
  otherwise { flag_for_review(email) }
end
```

## Feelings.while

A bounded loop that keeps calling your block while a value still feels a certain way.

```ruby
draft = Feelings.while(draft, "full of corporate jargon", max: 5) { |current| rewrite(current) }
```

It raises `Feelings::LoopLimit` if the value still feels that way after `max` iterations.

## Chaos

`Feelings.chaos` samples from the answer's probability distribution instead of always taking
the top pick, useful for simulations and load-testing prompts.

```ruby
Feelings.chaos { Feelings(email).most_like(KINDS) }
```

## Record and replay

Record a real run once, then replay it in tests without ever calling a judge again.

```ruby
tape = Feelings.record { Feelings(email).like?("spam") }
Feelings.replay(tape) { Feelings(email).like?("spam") } # judge is never called
```

A tape round-trips through JSON with `tape.to_json` and `Feelings::Tape.from_json`.

## Core extension

```ruby
require "feelings/core_ext"

email.feels_like?("spam")
email.feels_most_like(KINDS)
```

## Testing with Stub

```ruby
Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9, kinds: :invitation)
Feelings(email).like?("spam") # => true, no network call
```

## Status

0.1.0. The API above is the whole surface.

## Releasing

Publishing runs through RubyGems trusted publishing, so no API key is stored
anywhere. To ship a version:

1. Bump `lib/feelings/version.rb`.
2. Add the version to `CHANGELOG.md`.
3. Merge to `main`. The Release workflow runs the suite, builds the gem with
   `gem build --strict`, checks the built gem carries every file under
   `lib/`, and pushes it. A version already on RubyGems is skipped, so the
   workflow is safe to re-run.

The same workflow can be started by hand from the Actions tab or with
`gh workflow run release.yml`.
