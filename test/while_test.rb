# frozen_string_literal: true

require_relative "test_helper"

class WhileTest < Minitest::Test
  def test_while_returns_final_value_once_it_no_longer_feels_true
    probabilities = [0.9, 0.9, 0.2]
    Feelings.judge = SequenceStub.new(probabilities)

    result = Feelings.while("draft v0", "full of corporate jargon", max: 5) do |current|
      "#{current}+rewrite"
    end

    assert_equal "draft v0+rewrite+rewrite", result
  end

  def test_while_raises_loop_limit_when_still_true_after_max
    Feelings.judge = SequenceStub.new([0.9, 0.9, 0.9])

    error = assert_raises(Feelings::LoopLimit) do
      Feelings.while("draft", "full of corporate jargon", max: 3) { |current| "#{current}+r" }
    end
    assert_match(/still feels true after 3 iterations/, error.message)
  end

  def test_while_validates_max_range
    assert_raises(ArgumentError) { Feelings.while("draft", "jargon", max: 0) { |c| c } }
    assert_raises(ArgumentError) { Feelings.while("draft", "jargon", max: 51) { |c| c } }
  end

  class SequenceStub
    def initialize(probabilities)
      @probabilities = probabilities.dup
    end

    def call(state:, questions:)
      probability = @probabilities.shift
      questions.each_with_object({}) { |(id, _), h| h[id] = { noul: probability, probabilities: {}, model: "seq" } }
    end
  end
end
