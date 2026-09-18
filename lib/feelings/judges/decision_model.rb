# frozen_string_literal: true

module Feelings
  module Judges
    # The default judge: wraps a RubyDecisionModel::Client and re-raises
    # any RubyDecisionModel::Error as a Feelings::JudgeError.
    class DecisionModel
      def initialize(client)
        @client = client
      end

      def call(state:, questions:)
        response = @client.ask(state: state, questions: questions)
        model = response.model

        questions.each_with_object({}) do |(id, question), result|
          answer = response[id.to_s]
          raise JudgeError, "no answer returned for #{id.inspect}" unless answer

          result[id] = convert(question, answer, model)
        end
      rescue RubyDecisionModel::Error => e
        raise JudgeError, "ruby_decision_model error: #{e.message}"
      end

      private

      def convert(question, answer, model)
        if question["type"] == "noul"
          { noul: answer.noul, probabilities: answer.probabilities, model: model }
        else
          { choice: answer.choice, confidence: answer.confidence, probabilities: answer.probabilities, model: model }
        end
      end
    end
  end
end
