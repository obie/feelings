# Labels and match

`most_like` and `pick` ask which of a set of labels best fits a value. `match` dispatches on
the winning label directly.

## most_like

`most_like` returns the winning label as a symbol:

```ruby
KINDS = { invitation: "an invitation to an event", sales_pitch: "someone selling something" }
Feelings(email).most_like(KINDS) # => :invitation
```

## pick and the Pick object

`pick` returns the full `Pick` object instead of just the label:

```ruby
pick = Feelings(email).pick(KINDS)
pick.label          # => :invitation
pick.confidence      # => the winning label's probability
pick.probabilities   # => { invitation: 0.7, sales_pitch: 0.3 }
pick.model           # => the model name reported by the judge
pick.to_h             # => { label:, confidence:, probabilities:, model: }
```

`most_like` is `pick(...)&.label`.

## Label sets as symbol => description hashes

A label set is a `Hash` of `Symbol => description`. String keys are accepted and converted to
symbols.

## Bare symbols

Pass bare symbols and each one resolves to its registered description, or a humanized version
of the symbol if it isn't registered:

```ruby
Feelings(email).most_like(:invitation, :sales_pitch)
```

## Mixed args

Bare symbols and an explicit trailing hash can be combined in the same call; the hash's
descriptions apply to its own keys:

```ruby
Feelings(email).most_like(:invitation, :sales_pitch, other: "anything else")
```

## confidence: gating

Pass `confidence:` to get `nil` back instead of a shaky pick. `most_like` and `pick` both
return `nil` when the winning label's confidence is below the threshold:

```ruby
Feelings(email).most_like(KINDS, confidence: 0.6) # nil if the winner scores below 0.6
```

## The 2..255 limit

A label set must have between 2 and 255 entries. Fewer than 2 or more than 255 raises
`Feelings::BadLabels`.

## The numeric-only description rule

A label description can't be a bare numeral (after stripping whitespace); `Feelings::BadLabels`
is raised if any description is numeric-only. Descriptions are what the model reads to decide
which label fits, so a description like `"1"` gives it nothing to judge against.

## match with on

`match` dispatches on the winning label with a block:

```ruby
Feelings(email).match(KINDS) do
  on(:invitation) { accept_invite(email) }
  on(:sales_pitch, :other) { archive(email) }
  otherwise { flag_for_review(email) }
end
```

`match` runs the block for the branch whose keys include the winning label, and returns that
branch's block's value. With no matching branch and no `otherwise`, `match` returns `nil`.

## Multi-key on

`on` accepts more than one label, and the branch runs if the winner is any of them:

```ruby
on(:sales_pitch, :other) { archive(email) }
```

## otherwise

`otherwise { ... }` runs when no `on` branch matches the winning label.

## Inline descriptions in on

`on` accepts a trailing string as an inline description for its keys, letting you skip the
`labels` argument to `match` entirely:

```ruby
Feelings(email).match do
  on(:small, "a small thing") { :is_small }
  on(:big, "a big thing") { :is_big }
end
```

`confidence:` on `match` works the same as on `pick`: it's passed straight through to the
underlying pick.

Next: [The Registry and YAML](registry.md).
