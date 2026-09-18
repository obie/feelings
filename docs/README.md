# Documentation

- [Getting Started](getting-started.md): install, API keys, your first `like?` call.
- [Asking Questions](asking.md): `like?`, `like`, the Mood object, `at_least:`, the maybe band.
- [Labels and match](labels.md): `most_like`, `pick`, label sets, `match` with `on`.
- [The Registry and YAML](registry.md): `Feelings.register`, `Feelings.load`, the Rails railtie.
- [State](state.md): what gets sent to a judge, `to_feelings_state`, the resolution order.
- [Batching](batching.md): the hash form of `like?`/`like`, one request per call.
- [Feelings.while](loops.md): bounded rewrite loops, `max:`, `LoopLimit`.
- [Chaos, Record, and Replay](chaos-and-tapes.md): probability sampling, tapes, replay.
- [Testing](testing.md): the Stub judge, `with_judge`, tapes in tests.
- [Judges](judges.md): the judge protocol, the default judge, writing your own.
- [API Reference](reference.md): every public method, class, and error.
