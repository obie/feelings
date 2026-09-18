# Asking Questions

`like?` and `like` ask a yes/no question about a value. Both live on the wrapper returned by
`Feelings(value)`.

## like?

`like?` returns `true`, `false`, or `nil`.

```ruby
f = Feelings(email.body)
f.like?("spam")
```

With no `at_least:`, the split is at 0.5: a probability of 0.5 or higher is `true`, otherwise
`false`. `like?` never returns `nil` unless you pass `at_least:`.

## like

`like` returns a `Mood` you can branch on, or, given a block, runs the block and returns
whatever the matching branch returns.

```ruby
f.like("full of corporate jargon") do |mood|
  mood.yes   { rewrite(draft) }
  mood.maybe { flag_for_review(draft) }
  mood.no    { draft }
end
```

Without a block, `like` just returns the `Mood`:

```ruby
mood = f.like("spam")
mood.yes?          # => true/false
mood.label         # => "yes", "maybe", or "no"
mood.probability    # => the raw probability
mood.to_bool        # => true, false, or nil (nil for "maybe")
mood.to_h            # => { label:, probability:, description:, value:, model: }
```

## The Mood object

A `Mood` wraps one noul (yes/no) answer: `probability`, `description`, `value`, `model`,
`at_least`, plus a `label` computed from all of those. `yes?`, `maybe?`, and `no?` test the
label. Inside a block passed to `like`, calling `mood.yes { ... }`, `mood.maybe { ... }`, or
`mood.no { ... }` registers a branch; once the block returns, `like` dispatches to the branch
matching the label and returns its value. Call `mood.yes { ... }` etc. outside a block and it
runs immediately if the label already matches.

## at_least:

Pass `at_least:` to set your own probability floor. `like?` then returns `nil` for the middle
zone instead of forcing a guess:

```ruby
f.like?("a security incident", at_least: 0.8) # true, false, or nil
```

## The maybe branch and the 0.3/0.7 bands

Declaring a `maybe` branch inside a `like` block turns the yes/maybe/no split into bands
automatically, even with no `at_least:` given. This is branch registration, not source
introspection: the bands turn on because you called `mood.maybe { ... }` while the block was
being collected, not because the source text mentions `maybe`.

```ruby
result = Feelings("draft").like("jargon") do |mood|
  mood.yes   { :yes_branch }
  mood.maybe { :maybe_branch }
  mood.no    { :no_branch }
end
```

## Exactly how yes/maybe/no are decided

Given a probability `p` for the value feeling like the description:

- **With `at_least:` set, or with a `maybe` branch declared and no `at_least:`:** the
  threshold is `at_least` (defaulting to 0.7 when only the maybe branch turned banding on).
  `p` is `"maybe"` when `p < threshold` and `p > 1 - threshold`. That's the 0.3/0.7 band when
  the threshold is 0.7. Outside the band, `p >= threshold` is `"yes"`, otherwise `"no"`.
- **With neither `at_least:` nor a `maybe` branch:** there's no maybe zone. The split is at
  0.5: `p >= 0.5` is `"yes"`, otherwise `"no"`.

A `like` block with `yes`/`no` branches and no `maybe` branch stays at the 0.5 split even at a
probability of exactly 0.5, it lands on `yes`.

Inside `Feelings.chaos`, a draw substitutes for the threshold comparison outside the band: `yes`
wins when the draw is less than the probability, `no` otherwise. See
[Chaos, Record, and Replay](chaos-and-tapes.md) for that mechanism.

## Memoization within a wrapper

`Feelings(value)` memoizes raw answers per question (by description, not by `at_least:`), so
asking the same question with a different floor reuses the judgment instead of paying for
another request:

```ruby
f = Feelings("mail")
f.like?("spam")
f.like?("spam", at_least: 0.8) # no second request
```

## Symbols vs strings

Pass a `String` to describe the question inline, or a `Symbol` to look it up in the
[registry](registry.md). An unregistered symbol is humanized (underscores become spaces) rather
than raising:

```ruby
f.like?(:spam)          # registry lookup if :spam is registered
f.like?(:sales_report)  # "sales report" if not registered
```

## Humanizing

`Labels.humanize` is what turns an unregistered symbol into a description: it replaces
underscores with spaces and nothing else. `:sales_report` becomes `"sales report"`.

Next: [Labels and match](labels.md).
