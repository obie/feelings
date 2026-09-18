# Getting Started

`feelings` brings the `feels` construct from the [Probably](https://probably-lang.southpolesteve.workers.dev/)
language to Ruby. A decision model reads a value and a description and returns a calibrated
probability instead of generated text. `feelings` turns that probability into things a Ruby
program can branch on: booleans, label picks, bounded loops, and semantic `match`.

## Install

Add the gem to your Gemfile:

```ruby
gem "feelings"
```

## API keys

No configuration is required beyond an API key. Set `OPENROUTER_API_KEY` or `TYPESAFE_API_KEY`
in your environment. `feelings` depends on [ruby_decision_model](https://rubygems.org/gems/ruby_decision_model),
which picks a provider automatically based on whichever key is present, and builds the default
judge the first time you ask it something. It works with Jev through OpenRouter or through
Typesafe's own API.

## Your first question

```ruby
require "feelings"

Feelings("that email").like?("genuinely urgent")
# => true or false
```

`Feelings(value)` wraps a Ruby object and returns a `Feelings::About`. Everything else in this
gem, `like?`, `like`, `most_like`, `pick`, and `match`, is a method on that wrapper.

## What a decision model is

A decision model answers a typed question about a value with a calibrated probability rather
than a block of text. `feelings` sends it a description of what you're asking about and the
value in question, and gets back a probability (for a yes/no question) or a probability spread
over a set of labels (for a choice among options).

## What `Feelings(value)` returns

`Feelings(value)` returns a `Feelings::About` instance. It resolves the value into wire state
once, on construction, and memoizes answers per question, so asking the same thing twice on the
same wrapper never re-judges. See [State](state.md) for how a value turns into wire state, and
[Asking Questions](asking.md) for what you can do with the wrapper.

Next: [Asking Questions](asking.md).
