# Judges

A judge is whatever answers the questions `feelings` builds. `Feelings.judge` holds the current
one; `Feelings.judge =` sets it.

## The judge protocol

A judge is any object responding to:

```ruby
call(state:, questions:)
```

`state` is a Hash like `{ "value" => resolved_value }`. `questions` is a Hash of
id => question hash, where each question hash was built by `RubyDecisionModel::Questions.noul`
or `.choice` (a noul question has `question["type"] == "noul"`; a choice question does not).
`call` must return a Hash keyed by the same ids (or their string equivalents; `feelings` checks
both), where each value is itself a Hash:

- **A noul answer**: `{ noul: Float, probabilities: Hash, model: String }`. `probabilities` may
  be empty.
- **A choice answer**: `{ choice: Symbol or String, confidence: Float, probabilities: Hash, model: String }`.

If a judge returns no answer for a question id, `feelings` raises `Feelings::JudgeError`.

## The default judge: DecisionModel

`Feelings::Judges::DecisionModel` wraps a `RubyDecisionModel::Client` and adapts its typed
responses to the judge protocol above:

```ruby
Feelings::Judges::DecisionModel.new(RubyDecisionModel::Client.new)
```

`Feelings.judge`, called with no judge yet assigned, builds one of these automatically around
`RubyDecisionModel.client` (the memoized default client, which auto-detects `OPENROUTER_API_KEY`
or `TYPESAFE_API_KEY`).

### How it maps errors

`DecisionModel#call` sends `client.ask(state:, questions:)` and converts each
`RubyDecisionModel::Answers::Noul` or `::Choice` into the judge protocol's plain hash shape,
tagging every answer with `response.model`. Any `RubyDecisionModel::Error` raised by the client
(covering configuration problems, transport failures, and API errors alike) is caught and
re-raised as `Feelings::JudgeError`, so callers only ever need to rescue one error class
regardless of which provider or failure mode was underneath.

## Providers

`RubyDecisionModel::Client` talks to a decision model provider, selected by whichever of
`OPENROUTER_API_KEY` / `TYPESAFE_API_KEY` is set in the environment (or picked explicitly with
`provider:`). `feelings` doesn't touch provider selection itself; that's entirely
`ruby_decision_model`'s job, wrapped by `Judges::DecisionModel`.

## Writing your own judge

Anything answering the protocol works. Here's a judge that always answers yes at a fixed
probability, in fifteen lines:

```ruby
class AlwaysYes
  def initialize(probability = 0.9, model: "always-yes")
    @probability = probability
    @model = model
  end

  def call(state:, questions:)
    questions.each_with_object({}) do |(id, question), result|
      result[id] =
        if question["type"] == "noul"
          { noul: @probability, probabilities: {}, model: @model }
        else
          label = question["criteria"].keys.first
          { choice: label, confidence: 1.0, probabilities: { label => 1.0 }, model: @model }
        end
    end
  end
end

Feelings.judge = AlwaysYes.new
```

Next: [API Reference](reference.md).
