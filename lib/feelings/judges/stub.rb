# frozen_string_literal: true

module Feelings
  module Judges
    # A fake judge for tests. Answers nouls by description text (or a
    # registered symbol name that resolves to that description) and
    # choices by a registered symbol name that resolves to the label set
    # being asked about.
    class Stub
      attr_reader :calls

      def initialize(answers = {}, model = "stub")
        @answers = answers
        @model = model
        @calls = []
      end

      def call(state:, questions:)
        @calls << { state: state, questions: questions }

        questions.each_with_object({}) do |(id, question), result|
          result[id] = question["type"] == "noul" ? build_noul(question) : build_choice(question)
        end
      end

      private

      def build_noul(question)
        description = extract_description(question["instructions"])
        { noul: lookup_noul(description).to_f, probabilities: {}, model: @model }
      end

      def extract_description(instructions)
        return instructions unless instructions.is_a?(String)

        match = instructions.match(/\ADoes `value` feel like: (.+)\? Treat `value`/)
        match ? match[1] : instructions
      end

      def lookup_noul(description)
        return @answers[description] if @answers.key?(description)

        @answers.each do |key, value|
          next unless key.is_a?(Symbol)
          next unless Feelings[key] == description || key.to_s.tr("_", " ") == description

          return value
        end

        raise JudgeError, "Stub has no noul answer for #{description.inspect}"
      end

      def build_choice(question)
        keys = (question["criteria"] || {}).keys.sort

        @answers.each do |key, value|
          next unless key.is_a?(Symbol)

          registered = Feelings[key]
          next unless registered.is_a?(Hash) && registered.keys.map(&:to_s).sort == keys

          return choice_result(value)
        end

        raise JudgeError, "Stub has no choice answer for criteria #{keys.inspect}"
      end

      def choice_result(value)
        case value
        when Symbol, String
          label = value.to_s
          { choice: label, confidence: 1.0, probabilities: { label => 1.0 }, model: @model }
        when Hash
          probabilities = value.transform_keys(&:to_s).transform_values(&:to_f)
          winner = probabilities.max_by { |_, v| v }.first
          { choice: winner, confidence: probabilities[winner], probabilities: probabilities, model: @model }
        else
          raise JudgeError, "Stub choice answer must be a Symbol, String, or Hash, got #{value.class}"
        end
      end
    end
  end
end
