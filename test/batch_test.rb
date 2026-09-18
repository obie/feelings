# frozen_string_literal: true

require_relative "test_helper"

class BatchTest < Minitest::Test
  def setup
    super
    Feelings.load(fixture_path("feelings.yml"))
  end

  def test_like_predicate_hash_batches_into_one_request
    stub = Feelings::Judges::Stub.new("spam email" => 0.1, urgent: 0.9, kinds: :invitation)
    Feelings.judge = stub

    result = Feelings("mail").like?(spam: "spam email", urgent: :urgent, kind: :kinds)

    assert_equal({ spam: false, urgent: true, kind: :invitation }, result)
    assert_equal 1, stub.calls.size
    assert_equal 3, stub.calls.first[:questions].size
  end

  def test_like_hash_batch_returns_mood_and_pick_objects
    stub = Feelings::Judges::Stub.new("spam email" => 0.9, kinds: :invitation)
    Feelings.judge = stub

    result = Feelings("mail").like(spam: "spam email", kind: :kinds)

    assert_instance_of Feelings::Mood, result[:spam]
    assert_instance_of Feelings::Pick, result[:kind]
    assert_equal :invitation, result[:kind].label
    assert_equal 1, stub.calls.size
  end
end
