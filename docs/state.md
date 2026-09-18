# State

`Feelings(value)` resolves the value you hand it into wire state once, when the wrapper is
constructed, and sends that state to the judge with every question asked on that wrapper.

## What gets sent

State is resolved by `Feelings::State.resolve`, and wrapped as `{ "value" => resolved }` before
it goes to the judge. `Feelings::About#value` still returns your original, unresolved object;
only the wire state is transformed.

## The `{"value" => ...}` wire shape

Every question sent to a judge carries the same `state` hash, keyed by the single string
`"value"`. `Feelings::Questions.state_for(value)` is what builds it.

## to_feelings_state

If the object responds to `to_feelings_state`, that return value is used as-is, with no further
resolution:

```ruby
class Ticket
  def to_feelings_state
    { untouched: :symbol_stays }
  end
end
```

Whatever `to_feelings_state` returns goes straight onto the wire, symbols and all. This takes
priority over every other resolution rule below, including when the object is nested inside a
Hash or Array being resolved.

## Scalars

A `String`, `Numeric`, `true`, `false`, or `nil` passes through unchanged.

## Hash/Array recursion

A `Hash`'s keys are stringified and its values resolved recursively. An `Array`'s elements are
resolved recursively, each following the same rules (including calling `to_feelings_state` on
any element that defines it).

## as_json

If none of the above apply and the object responds to `as_json`, `resolve` is called again on
whatever `as_json` returns, so a Hash or Array coming back from `as_json` still gets stringified
and recursed the normal way.

## UnknownState

Anything else raises `Feelings::UnknownState`, naming the object's class and telling you to
define `to_feelings_state` or `as_json`.

## Why send only the fields the question needs

State goes to a judge over the network and becomes part of every prompt. `to_feelings_state`
exists so you can send a minimal projection of an object, the fields the question actually needs
to answer, rather than an entire record's worth of columns.

## An ActiveRecord example

```ruby
class Ticket < ApplicationRecord
  def to_feelings_state
    { "subject" => subject, "body" => body, "reporter_role" => reporter.role }
  end
end

Feelings(ticket).like?("a security incident", at_least: 0.8)
```

Next: [Batching](batching.md).
