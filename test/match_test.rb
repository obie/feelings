# frozen_string_literal: true

require_relative "test_helper"

class MatchTest < Minitest::Test
  KINDS = { invitation: "an invitation to an event", sales_pitch: "someone selling something",
            other: "anything else" }.freeze

  def setup
    super
    Feelings.load(fixture_path("feelings.yml"))
  end

  def test_match_dispatches_to_matching_branch
    Feelings.judge = Feelings::Judges::Stub.new(kinds: :invitation)
    result = Feelings("mail").match(KINDS) do
      on(:invitation) { :accepted }
      on(:sales_pitch, :other) { :archived }
    end
    assert_equal :accepted, result
  end

  def test_match_supports_multi_key_on
    Feelings.judge = Feelings::Judges::Stub.new(kinds: :other)
    result = Feelings("mail").match(KINDS) do
      on(:invitation) { :accepted }
      on(:sales_pitch, :other) { :archived }
    end
    assert_equal :archived, result
  end

  def test_match_runs_otherwise_when_no_branch_matches
    Feelings.judge = Feelings::Judges::Stub.new(kinds: :sales_pitch)
    result = Feelings("mail").match(KINDS) do
      on(:invitation) { :accepted }
      otherwise { :fallback }
    end
    assert_equal :fallback, result
  end

  def test_match_returns_nil_with_no_matching_branch_and_no_otherwise
    Feelings.judge = Feelings::Judges::Stub.new(kinds: :sales_pitch)
    result = Feelings("mail").match(KINDS) { on(:invitation) { :accepted } }
    assert_nil result
  end

  def test_match_accepts_inline_on_descriptions_with_no_labels_argument
    Feelings.load(fixture_path("sizes.yml"))
    Feelings.judge = Feelings::Judges::Stub.new(sizes: :small)
    result = Feelings("mail").match do
      on(:small, "a small thing") { :is_small }
      on(:big, "a big thing") { :is_big }
    end
    assert_equal :is_small, result
  end
end
