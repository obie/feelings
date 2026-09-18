# The Registry and YAML

Keep descriptions and label sets out of the codebase and register them once, from YAML or from
plain Ruby.

## Feelings.register

Register descriptions and label sets straight from Ruby, no file involved:

```ruby
Feelings.register(spam: "an unsolicited commercial email", kinds: KINDS)
```

`register` expects a `Hash`; anything else raises `ArgumentError`.

## Feelings.load

Load a YAML file into the registry:

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

The YAML file must contain a mapping at the top level; anything else raises `ArgumentError`.

## Precedence rules

`Feelings.load` and `Feelings.register` can both be called more than once. Later calls override
earlier keys. Loading and registering merge together the same way, so a later `load` overrides
an earlier `register`, and a later `register` overrides an earlier `load`.

## Structured descriptions

A registered value doesn't have to be a plain string. A hash description, registered under a
key, is passed straight into a noul question's instructions as structured data rather than
interpolated into a sentence:

```yaml
shaped:
  tone: friendly
  topic: billing
```

```ruby
Feelings.load("config/feelings.yml")
Feelings(email).like?(:shaped)
```

## YAML is optional and lazily required

`Feelings.load` calls `require "yaml"` itself, only when it's actually invoked. Plain
`require "feelings"` never pulls in the YAML library.

## The Rails railtie

When `Rails::Railtie` is defined, `feelings` loads a railtie that, after Rails initializes,
loads `config/feelings.yml` automatically if that file exists.

## Feelings[:key]

Look up a registered description or label set directly:

```ruby
Feelings[:spam]   # => "an unsolicited commercial email"
Feelings[:kinds]  # => { invitation: "...", sales_pitch: "...", other: "..." }
```

Registered values, and any nested hashes or arrays inside them, come back frozen. An unknown
key returns `nil`.

## reset!

`Feelings.reset!` clears the registry back to empty, and also resets the judge and the random
source back to their defaults. Every construct works fine with an empty registry and no config
file; nothing here is required.

Next: [State](state.md).
