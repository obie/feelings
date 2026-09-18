# frozen_string_literal: true

require_relative "test_helper"

class RaisingJudge
  def call(state:, questions:)
    raise "the judge should never be called during replay"
  end
end

class ReplayTest < Minitest::Test
  def test_replay_never_calls_the_judge
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9)
    tape = Feelings.record { Feelings("mail").like?("spam") }

    Feelings.judge = RaisingJudge.new
    result = Feelings.replay(tape) { Feelings("mail").like?("spam") }

    assert_equal true, result
  end

  def test_replay_raises_on_value_mismatch
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9)
    tape = Feelings.record { Feelings("mail").like?("spam") }

    Feelings.judge = RaisingJudge.new
    assert_raises(Feelings::ReplayMismatch) do
      Feelings.replay(tape) { Feelings("a different mail").like?("spam") }
    end
  end

  def test_replay_raises_on_leftover_entries
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9, "urgent" => 0.1)
    tape = Feelings.record do
      Feelings("mail").like?("spam")
      Feelings("mail").like?("urgent")
    end

    Feelings.judge = RaisingJudge.new
    assert_raises(Feelings::ReplayMismatch) do
      Feelings.replay(tape) { Feelings("mail").like?("spam") }
    end
  end
end
