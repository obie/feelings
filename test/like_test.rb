# frozen_string_literal: true

require_relative "test_helper"

class LikeTest < Minitest::Test
  def test_like_predicate_splits_at_half_with_no_at_least
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.6)
    assert_equal true, Feelings("mail").like?("spam")

    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.4)
    assert_equal false, Feelings("mail").like?("spam")
  end

  def test_like_predicate_never_returns_nil_without_at_least
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.5)
    refute_nil Feelings("mail").like?("spam")
  end

  def test_at_least_returns_three_states
    Feelings.judge = Feelings::Judges::Stub.new("urgent" => 0.9)
    assert_equal true, Feelings("mail").like?("urgent", at_least: 0.8)

    Feelings.judge = Feelings::Judges::Stub.new("urgent" => 0.05)
    assert_equal false, Feelings("mail").like?("urgent", at_least: 0.8)

    Feelings.judge = Feelings::Judges::Stub.new("urgent" => 0.5)
    assert_nil Feelings("mail").like?("urgent", at_least: 0.8)
  end

  def test_maybe_branch_declared_without_at_least_uses_default_bands
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.5)
    result = Feelings("draft").like("jargon") do |mood|
      mood.yes   { :yes_branch }
      mood.maybe { :maybe_branch }
      mood.no    { :no_branch }
    end
    assert_equal :maybe_branch, result
  end

  def test_without_maybe_branch_bands_stay_at_half
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.5)
    result = Feelings("draft").like("jargon") do |mood|
      mood.yes { :yes_branch }
      mood.no  { :no_branch }
    end
    assert_equal :yes_branch, result
  end

  def test_block_return_value_is_returned_by_like
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.9)
    result = Feelings("draft").like("jargon", at_least: 0.7) do |mood|
      mood.yes { "rewritten" }
      mood.no  { "unchanged" }
    end
    assert_equal "rewritten", result
  end

  def test_like_block_returns_nil_when_no_branch_declared_for_outcome
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.1)
    result = Feelings("draft").like("jargon", at_least: 0.7) { |mood| mood.yes { "rewritten" } }
    assert_nil result
  end

  def test_mood_accessors
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9)
    mood = Feelings("mail").like("spam")
    assert_predicate mood, :yes?
    refute_predicate mood, :maybe?
    refute_predicate mood, :no?
    assert_equal "yes", mood.label
    assert_in_delta 0.9, mood.probability
    assert_equal "spam", mood.description
    assert_equal "mail", mood.value
    assert_equal "stub", mood.model
    assert_equal(
      { label: "yes", probability: 0.9, description: "spam", value: "mail", model: "stub" },
      mood.to_h
    )
  end

  def test_symbol_description_uses_registry_when_present
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(spam: 0.8)
    assert_equal true, Feelings("mail").like?(:spam)
  end

  def test_symbol_description_humanizes_when_not_registered
    Feelings.judge = Feelings::Judges::Stub.new("sales report" => 0.9)
    assert_equal true, Feelings("mail").like?(:sales_report)
  end

  def test_memoization_within_a_wrapper
    stub = Feelings::Judges::Stub.new("spam" => 0.9)
    Feelings.judge = stub
    about = Feelings("mail")
    about.like?("spam")
    about.like?("spam")
    assert_equal 1, stub.calls.size
  end

  def test_no_judge_raises
    Feelings.judge = nil
    assert_raises(Feelings::NoJudge) { Feelings("mail").like?("spam") }
  end

  def test_with_judge_overrides_temporarily
    default = Feelings::Judges::Stub.new("spam" => 0.1)
    override = Feelings::Judges::Stub.new("spam" => 0.9)
    Feelings.judge = default

    result = Feelings.with_judge(override) { Feelings("mail").like?("spam") }
    assert_equal true, result
    assert_equal false, Feelings("mail").like?("spam")
  end
end
