# frozen_string_literal: true

module Feelings
  # Shared machinery behind every like/like?/most_like/match call: builds
  # wire questions, calls (or replays) the judge once per invocation, and
  # classifies the raw answers into Mood/Pick shaped results.
  module Engine
    module_function

    # specs: Hash id => { kind: :noul, description: ... } or
    #                    { kind: :choice, labels: { sym => desc } }
    # Returns Hash id => { kind:, probability:/choice:/confidence:, probabilities:, model:, draw: }
    def call(value:, specs:)
      state = Questions.state_for(value)
      wire_questions = {}
      specs.each { |id, spec| wire_questions[id] = build_question(spec) }

      replay_queue = Feelings.current_replay
      chaos = Feelings.chaos?
      recording = Feelings.current_tape

      raw_answers = if replay_queue
                      replay_answers(replay_queue, state, wire_questions)
                    else
                      judge = Feelings.current_judge
                      raise NoJudge, "no judge is configured" if judge.nil?

                      judge.call(state: state, questions: wire_questions)
                    end

      results = {}
      specs.each do |id, spec|
        answer = raw_answers[id] || raw_answers[id.to_s]
        raise JudgeError, "judge returned no answer for #{id.inspect}" unless answer

        answer = symbolize(answer)
        model = answer[:model]
        draw = nil

        outcome =
          case spec[:kind]
          when :noul
            probability = answer[:noul].to_f
            probabilities = answer[:probabilities] || {}
            if replay_queue
              draw = answer[:draw]
            elsif chaos
              draw = Feelings.random.call
            end
            { probability: probability, probabilities: probabilities }
          when :choice
            choice = answer[:choice]
            choice = choice.to_sym if choice.respond_to?(:to_sym)
            probabilities = symbolize_probabilities(answer[:probabilities] || {})
            if replay_queue
              draw = answer[:draw]
            elsif chaos
              draw = Feelings.random.call
              choice = Distribution.sample(probabilities, draw) unless probabilities.empty?
            end
            { choice: choice, confidence: answer[:confidence].to_f, probabilities: probabilities }
          else
            raise ArgumentError, "unknown spec kind #{spec[:kind].inspect}"
          end

        results[id] = outcome.merge(kind: spec[:kind], model: model, draw: draw)

        next unless recording

        recording << Tape::Entry.new(
          kind: spec[:kind].to_s,
          value: state["value"],
          question: wire_questions[id],
          answer: answer.reject { |k, _| k == :draw },
          model: model,
          draw: draw
        )
      end
      results
    end

    def build_question(spec)
      case spec[:kind]
      when :noul
        RubyDecisionModel::Questions.noul(Questions.noul_instructions(spec[:description]))
      when :choice
        criteria = {}
        spec[:labels].each { |symbol, description| criteria[symbol] = description }
        RubyDecisionModel::Questions.choice(Questions.choice_instructions, criteria: criteria)
      else
        raise ArgumentError, "unknown spec kind #{spec[:kind].inspect}"
      end
    end

    def replay_answers(replay_queue, state, wire_questions)
      answers = {}
      wire_questions.each do |id, question|
        entry = replay_queue.shift
        if entry.nil?
          raise ReplayMismatch, "tape has no more entries but a question for #{id.inspect} was asked"
        end

        unless entry.value == state["value"] && entry.question == question
          raise ReplayMismatch,
                "tape entry does not match the question asked for #{id.inspect}: " \
                "expected value=#{entry.value.inspect} question=#{entry.question.inspect}, " \
                "got value=#{state['value'].inspect} question=#{question.inspect}"
        end

        answer = symbolize(entry.answer)
        answer[:draw] = entry.draw
        answers[id] = answer
      end
      answers
    end

    # Classifies a Noul probability into "yes"/"maybe"/"no". With at_least:
    # or the auto bands, anything strictly inside the uncertain zone is
    # "maybe" before any sampling happens. Outside that zone a chaos draw
    # samples yes with probability p; otherwise yes wins at or above the
    # floor (0.5 when no floor is set).
    def classify(probability, at_least: nil, banded: false, draw: nil)
      if at_least || banded
        threshold = at_least || 0.7
        return "maybe" if probability < threshold && probability > 1 - threshold
      end

      return (draw < probability ? "yes" : "no") if draw

      probability >= (at_least || 0.5) ? "yes" : "no"
    end

    def symbolize(hash)
      hash.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
    end

    def symbolize_probabilities(hash)
      hash.each_with_object({}) { |(k, v), h| h[k.to_sym] = v.to_f }
    end
  end
end
