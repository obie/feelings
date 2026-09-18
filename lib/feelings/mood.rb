# frozen_string_literal: true

module Feelings
  # The result of a like/like? question: a Noul answer classified into
  # yes/maybe/no bands.
  class Mood
    attr_reader :label, :probability, :description, :value, :model

    attr_reader :result

    def initialize(label:, probability:, description:, value:, model:)
      @label = label
      @probability = probability
      @description = description
      @value = value
      @model = model
      @ran = false
      @result = nil
    end

    def yes?
      label == "yes"
    end

    def maybe?
      label == "maybe"
    end

    def no?
      label == "no"
    end

    def ran?
      @ran
    end

    def yes
      return nil unless yes?

      run { yield if block_given? }
    end

    def maybe
      return nil unless maybe?

      run { yield if block_given? }
    end

    def no
      return nil unless no?

      run { yield if block_given? }
    end

    def to_bool
      return true if yes?
      return false if no?

      nil
    end

    def to_h
      { label: label, probability: probability, description: description, value: value, model: model }
    end

    private

    def run
      @ran = true
      @result = yield
    end
  end
end
