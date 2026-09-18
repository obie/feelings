# frozen_string_literal: true

require_relative "test_helper"
require "feelings/core_ext"

class CoreExtTest < Minitest::Test
  def test_feels_like_predicate
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9)
    assert_equal true, "mail".feels_like?("spam")
  end

  def test_feels_like_returns_mood
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9)
    mood = "mail".feels_like("spam")
    assert_instance_of Feelings::Mood, mood
  end

  def test_feels_most_like
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(kinds: :invitation)
    assert_equal :invitation, "mail".feels_most_like(:kinds)
  end
end
