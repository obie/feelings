# Feelings.while

`Feelings.while` is a bounded loop that keeps calling your block while a value still feels a
certain way.

```ruby
draft = Feelings.while(draft, "full of corporate jargon", max: 5) { |current| rewrite(current) }
```

## Semantics

Before each pass, `Feelings.while` asks whether the current value still feels like the
description. If it no longer does (`mood.no?`), the current value is returned immediately,
without another pass through the block. Otherwise the block runs, its return value becomes the
current value, and the loop asks again. Note the question is a plain `like`, without a `maybe`
band or an `at_least:` floor, so the yes/no split is the plain 0.5 line described in
[Asking Questions](asking.md); there's no maybe outcome inside `Feelings.while`.

## max:

`max:` bounds how many times the block can run, and must be between 1 and 50 inclusive;
anything outside that range raises `ArgumentError`. It defaults to 5.

## LoopLimit

If the value still feels like the description after `max` iterations, `Feelings.while` raises
`Feelings::LoopLimit` with a message like `"Loop still feels true after 5 iterations."`.

## The rewrite-until-it-no-longer-feels pattern

The natural use is iterative rewriting: keep transforming a draft until a description no longer
applies, and give up loudly if it's stuck.

```ruby
draft = Feelings.while(draft, "full of corporate jargon", max: 5) { |current| rewrite(current) }
```

If `rewrite` can't get the draft past the check within `max` passes, that's a `LoopLimit`, not a
silently truncated result, worth handling explicitly rather than swallowing.

Next: [Chaos, Record, and Replay](chaos-and-tapes.md).
