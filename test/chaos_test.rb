# frozen_string_literal: true

require_relative "test_helper"

class ChaosTest < Minitest::Test
  def test_chaos_never_samples_inside_the_maybe_band
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.5)

    [0.1, 0.9].each do |draw|
      Feelings.random = -> { draw }
      result = Feelings.chaos do
        Feelings("draft").like("jargon") { |mood| mood.yes { :yes }; mood.maybe { :maybe }; mood.no { :no } }
      end
      assert_equal :maybe, result, "a probability inside the band is maybe whatever the draw"
    end
  end

  def test_chaos_samples_noul_when_no_band_is_declared
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.5)

    Feelings.random = -> { 0.9 }
    result = Feelings.chaos { Feelings("draft").like("jargon") { |mood| mood.yes { :yes }; mood.no { :no } } }
    assert_equal :no, result

    Feelings.random = -> { 0.1 }
    result = Feelings.chaos { Feelings("draft").like("jargon") { |mood| mood.yes { :yes }; mood.no { :no } } }
    assert_equal :yes, result
  end

  def test_chaos_samples_outside_the_band
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.95)

    Feelings.random = -> { 0.01 }
    result = Feelings.chaos do
      Feelings("draft").like("jargon") { |mood| mood.yes { :yes }; mood.maybe { :maybe }; mood.no { :no } }
    end
    assert_equal :yes, result

    Feelings.random = -> { 0.99 }
    result = Feelings.chaos do
      Feelings("draft").like("jargon") { |mood| mood.yes { :yes }; mood.maybe { :maybe }; mood.no { :no } }
    end
    assert_equal :no, result, "a confident probability is sampled in chaos, so a 5% draw can land on no"
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
