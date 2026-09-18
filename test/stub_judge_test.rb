# frozen_string_literal: true

require_relative "test_helper"

class StubJudgeTest < Minitest::Test
  def test_string_key_answers_noul_by_description
    stub = Feelings::Judges::Stub.new("spam email" => 0.8)
    Feelings.judge = stub
    assert_equal true, Feelings("mail").like?("spam email")
  end

  def test_symbol_key_answers_noul_by_registered_name
    Feelings.load(fixture_path("feelings.yml"))
    stub = Feelings::Judges::Stub.new(spam: 0.8)
    Feelings.judge = stub
    assert_equal true, Feelings("mail").like?(:spam)
  end

  def test_symbol_key_answers_choice_with_single_label_and_full_probability
    Feelings.load(fixture_path("feelings.yml"))
    stub = Feelings::Judges::Stub.new(kinds: :invitation)
    Feelings.judge = stub
    pick = Feelings("mail").pick(:kinds)
    assert_equal :invitation, pick.label
    assert_in_delta 1.0, pick.confidence
  end

  def test_symbol_key_answers_choice_with_a_spread
    Feelings.load(fixture_path("feelings.yml"))
    stub = Feelings::Judges::Stub.new(kinds: { invitation: 0.3, sales_pitch: 0.7 })
    Feelings.judge = stub
    pick = Feelings("mail").pick(:kinds)
    assert_equal :sales_pitch, pick.label
    assert_in_delta 0.7, pick.confidence
  end

  def test_unknown_question_raises_judge_error
    stub = Feelings::Judges::Stub.new("something else" => 0.5)
    Feelings.judge = stub
    assert_raises(Feelings::JudgeError) { Feelings("mail").like?("spam email") }
  end

  def test_calls_records_every_request
    stub = Feelings::Judges::Stub.new("spam email" => 0.8, "urgent" => 0.2)
    Feelings.judge = stub
    Feelings("mail").like?("spam email")
    Feelings("mail").like?("urgent")
    assert_equal 2, stub.calls.size
  end
end
