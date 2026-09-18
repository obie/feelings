# frozen_string_literal: true

module Feelings
  # The result of a like/like? question: a Noul answer classified into
  # yes/maybe/no. Inside a `like` block the yes/maybe/no methods register
  # branches; the branch matching the final label runs once the block has
  # returned, so declaring a maybe branch is what turns the bands on.
  # Outside a block, yes/maybe/no run their block immediately when the
  # label matches.
  class Mood
    attr_reader :probability, :description, :value, :model, :result, :at_least

    def initialize(probability:, description:, value:, model:, at_least: nil, draw: nil)
      @probability = probability
      @description = description
      @value = value
      @model = model
      @at_least = at_least
      @draw = draw
      @branches = {}
      @collecting = false
      @ran = false
      @result = nil
    end

    def label
      Engine.classify(probability, at_least: at_least, banded: at_least.nil? && @branches.key?(:maybe), draw: @draw)
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

    def yes(&block)
      branch(:yes, block)
    end

    def maybe(&block)
      branch(:maybe, block)
    end

    def no(&block)
      branch(:no, block)
    end

    def to_bool
      return true if yes?
      return false if no?

      nil
    end

    def to_h
      { label: label, probability: probability, description: description, value: value, model: model }
    end

    # Runs the block that was given to `like`, collecting branches, then
    # dispatches to the one matching the label. Returns that branch's value.
    def collect
      @collecting = true
      yield self
      @collecting = false
      dispatch
    ensure
      @collecting = false
    end

    private

    def branch(name, block)
      return self unless block

      @branches[name] = block
      run(block) if !@collecting && label == name.to_s
      self
    end

    def dispatch
      block = @branches[label.to_sym]
      return nil unless block

      run(block)
    end

    def run(block)
      @ran = true
      @result = block.call
    end
  end
end
