# frozen_string_literal: true

require_relative "test_helper"

class ChaosTest < Minitest::Test
  def test_chaos_samples_noul_in_ambiguous_maybe_zone
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.5)

    Feelings.random = -> { 0.9 }
    result = Feelings.chaos do
      Feelings("draft").like("jargon") { |mood| mood.yes { :yes }; mood.maybe { :maybe }; mood.no { :no } }
    end
    assert_equal :no, result

    Feelings.random = -> { 0.1 }
    result = Feelings.chaos do
      Feelings("draft").like("jargon") { |mood| mood.yes { :yes }; mood.maybe { :maybe }; mood.no { :no } }
    end
    assert_equal :yes, result
  end

  def test_chaos_threshold_checked_first_for_certain_zones
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.95)
    Feelings.random = -> { 0.01 }

    result = Feelings.chaos do
      Feelings("draft").like("jargon") { |mood| mood.yes { :yes }; mood.maybe { :maybe }; mood.no { :no } }
    end
    assert_equal :yes, result, "a probability past the upper band should always be yes, regardless of the draw"
  end

  def test_chaos_samples_choice_using_registered_label_set
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(kinds: { invitation: 0.2, sales_pitch: 0.7, other: 0.1 })

    Feelings.random = -> { 0.85 }
    result = Feelings.chaos { Feelings("mail").most_like(:kinds) }
    assert_equal :sales_pitch, result

    Feelings.random = -> { 0.05 }
    result = Feelings.chaos { Feelings("mail").most_like(:kinds) }
    assert_equal :invitation, result
  end
end
