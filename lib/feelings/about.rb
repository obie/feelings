# frozen_string_literal: true

module Feelings
  # The wrapper returned by Feelings(value). Holds the value and memoizes
  # answers per question so asking the same thing twice never re-judges.
  class About
    attr_reader :value

    def initialize(value)
      @value = value
      @resolved_state = State.resolve(value)
      @memo = {}
    end

    def like?(arg = nil, at_least: nil, confidence: nil, **rest)
      hash = batch_hash(arg, rest)
      if hash
        return batch(hash, at_least: at_least, confidence: confidence).transform_values { |result| coerce_bool(result) }
      end

      ask_mood(arg, at_least: at_least).to_bool
    end

    def like(arg = nil, at_least: nil, confidence: nil, **rest, &block)
      hash = batch_hash(arg, rest)
      return batch(hash, at_least: at_least, confidence: confidence) if hash

      mood = ask_mood(arg, at_least: at_least)
      return mood unless block

      mood.collect(&block)
    end

    def most_like(*args, confidence: nil, **rest)
      args = args + [rest] unless rest.empty?
      labels = build_label_set(args)
      pick = ask_pick(labels, confidence: confidence)
      pick&.label
    end

    def pick(*args, confidence: nil, **rest)
      args = args + [rest] unless rest.empty?
      labels = build_label_set(args)
      ask_pick(labels, confidence: confidence)
    end

    def match(labels = nil, confidence: nil, &block)
      builder = MatchBuilder.new
      builder.instance_eval(&block) if block

      merged = labels ? Labels.resolve(labels) : {}
      builder.labels.each { |key, description| merged[key] = description }
      builder.branches.each do |branch|
        branch.keys.each { |key| merged[key] ||= Labels.description_for(key) }
      end
      Labels.validate!(merged)

      pick = ask_pick(merged, confidence: confidence)
      branch = pick && builder.branch_for(pick.label)

      if branch
        branch.block.call
      elsif builder.otherwise
        builder.otherwise.call
      end
    end

    private

    def batch_hash(arg, rest)
      if arg.is_a?(Hash)
        rest.empty? ? arg : arg.merge(rest)
      elsif !rest.empty?
        rest
      end
    end

    def coerce_bool(result)
      case result
      when Mood
        result.to_bool
      when Pick
        result.label
      else
        result
      end
    end

    # Raw answers are memoized per question so a second ask with a different
    # threshold reuses the judgment instead of paying for another request.
    def ask_mood(description, at_least:)
      resolved = resolve_description(description)
      answer = @memo[[:noul, resolved]] ||=
        Engine.call(value: @resolved_state, specs: { sole: { kind: :noul, description: resolved } })[:sole]
      build_mood(answer, resolved, at_least: at_least)
    end

    def ask_pick(labels, confidence:)
      answer = @memo[[:choice, labels]] ||=
        Engine.call(value: @resolved_state, specs: { sole: { kind: :choice, labels: labels } })[:sole]
      build_pick(answer, confidence: confidence)
    end

    def build_mood(answer, description, at_least:)
      Mood.new(
        probability: answer[:probability],
        description: description,
        value: value,
        model: answer[:model],
        at_least: at_least,
        draw: answer[:draw]
      )
    end

    def build_pick(answer, confidence:)
      pick = Pick.new(
        label: answer[:choice],
        confidence: answer[:confidence],
        probabilities: answer[:probabilities],
        model: answer[:model]
      )
      return nil if confidence && pick.confidence < confidence

      pick
    end

    def batch(hash, at_least: nil, confidence: nil)
      specs = {}
      descriptions = {}

      hash.each do |id, raw|
        kind, payload = classify_value(raw)
        if kind == :noul
          specs[id] = { kind: :noul, description: payload }
          descriptions[id] = payload
        else
          specs[id] = { kind: :choice, labels: payload }
        end
      end

      answers = Engine.call(value: @resolved_state, specs: specs)
      answers.each_with_object({}) do |(id, answer), results|
        results[id] = if specs[id][:kind] == :noul
                         build_mood(answer, descriptions[id], at_least: at_least)
                       else
                         build_pick(answer, confidence: confidence)
                       end
      end
    end

    def classify_value(raw)
      case raw
      when String
        [:noul, raw]
      when Hash, Array
        [:choice, Labels.resolve(raw)]
      when Symbol
        registered = Feelings[raw]
        if registered.is_a?(Hash)
          [:choice, Labels.resolve(registered)]
        else
          [:noul, registered.is_a?(String) ? registered : Labels.humanize(raw)]
        end
      else
        raise ArgumentError, "unsupported question value #{raw.inspect}"
      end
    end

    def resolve_description(description)
      case description
      when String
        description
      when Symbol
        registered = Feelings[description]
        registered.is_a?(String) || registered.is_a?(Hash) ? registered : Labels.humanize(description)
      else
        raise ArgumentError, "description must be a String or Symbol, got #{description.class}"
      end
    end

    def build_label_set(args)
      labels =
        if args.size == 1 && (args.first.is_a?(Symbol) || args.first.is_a?(Array) || args.first.is_a?(Hash))
          Labels.resolve(args.first)
        else
          args.each_with_object({}) do |arg, hash|
            case arg
            when Symbol
              hash[arg] = Labels.description_for(arg)
            when Hash
              arg.each { |key, description| hash[key.to_sym] = description }
            else
              raise BadLabels, "unsupported label argument #{arg.inspect}"
            end
          end
        end

      Labels.validate!(labels)
    end
  end
end
