# frozen_string_literal: true

require_relative "test_helper"

class TapeTest < Minitest::Test
  def test_record_captures_entries_with_model_and_no_draw_outside_chaos
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9)

    tape = Feelings.record { Feelings("mail").like?("spam") }

    assert_equal 1, tape.size
    entry = tape.entries.first
    assert_equal "noul", entry.kind
    assert_equal "mail", entry.value
    assert_equal "stub", entry.model
    assert_nil entry.draw
    assert_equal 0.9, entry.answer[:noul]
  end

  def test_record_captures_draw_only_under_chaos
    Feelings.judge = Feelings::Judges::Stub.new("jargon" => 0.5)
    Feelings.random = -> { 0.4 }

    tape = Feelings.chaos do
      Feelings.record do
        Feelings("draft").like("jargon") { |mood| mood.yes { }; mood.maybe { }; mood.no { } }
      end
    end

    entry = tape.entries.first
    assert_in_delta 0.4, entry.draw
  end

  def test_tape_is_enumerable
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9, "urgent" => 0.1)
    tape = Feelings.record do
      Feelings("mail").like?("spam")
      Feelings("mail").like?("urgent")
    end

    assert_equal 2, tape.count
    assert_equal %w[noul noul], tape.map(&:kind)
  end

  def test_tape_round_trips_through_json
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9)
    tape = Feelings.record { Feelings("mail").like?("spam") }

    json = tape.to_json
    restored = Feelings::Tape.from_json(json)

    assert_equal tape.size, restored.size
    assert_equal tape.entries.first.kind, restored.entries.first.kind
    assert_equal tape.entries.first.value, restored.entries.first.value
    assert_equal tape.entries.first.model, restored.entries.first.model
  end
end
