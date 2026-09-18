# frozen_string_literal: true

module Feelings
  # The result of a most_like/pick question: a Choice answer.
  class Pick
    attr_reader :label, :confidence, :probabilities, :model

    def initialize(label:, confidence:, probabilities:, model:)
      @label = label
      @confidence = confidence
      @probabilities = probabilities
      @model = model
    end

    def to_h
      { label: label, confidence: confidence, probabilities: probabilities, model: model }
    end
  end
end
