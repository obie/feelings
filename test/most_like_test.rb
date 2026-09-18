# frozen_string_literal: true

require_relative "test_helper"

class MostLikeTest < Minitest::Test
  KINDS = { invitation: "an invitation to an event", sales_pitch: "someone selling something",
            other: "anything else" }.freeze

  def test_most_like_returns_symbol
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(kinds: :invitation)
    assert_equal :invitation, Feelings("mail").most_like(KINDS)
  end

  def test_pick_returns_pick_object
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(kinds: { invitation: 0.7, sales_pitch: 0.3 })
    pick = Feelings("mail").pick(KINDS)
    assert_instance_of Feelings::Pick, pick
    assert_equal :invitation, pick.label
    assert_in_delta 0.7, pick.confidence
    assert_equal "stub", pick.model
    assert_equal({ invitation: 0.7, sales_pitch: 0.3 }, pick.probabilities)
  end

  def test_most_like_with_registered_symbol_label_set
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(kinds: :sales_pitch)
    assert_equal :sales_pitch, Feelings("mail").most_like(:kinds)
  end

  def test_mixed_args_combine_bare_symbols_and_explicit_hash
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(kinds: { invitation: 0.2, sales_pitch: 0.2, other: 0.6 })
    result = Feelings("mail").most_like(:invitation, :sales_pitch, other: "anything else")
    assert_equal :other, result
  end

  def test_confidence_gate_returns_nil_below_threshold
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(kinds: { invitation: 0.55, sales_pitch: 0.45 })
    assert_nil Feelings("mail").most_like(KINDS, confidence: 0.6)
  end

  def test_labels_must_have_at_least_two_entries
    assert_raises(Feelings::BadLabels) { Feelings("mail").most_like(only: "one") }
  end

  def test_labels_reject_more_than_255_entries
    huge = (1..256).each_with_object({}) { |i, h| h[:"label_#{i}"] = "description #{i}" }
    assert_raises(Feelings::BadLabels) { Feelings("mail").most_like(huge) }
  end

  def test_labels_reject_numeric_only_keys
    assert_raises(Feelings::BadLabels) { Feelings("mail").most_like({ "1": "one", "2": "two" }) }
  end
end
