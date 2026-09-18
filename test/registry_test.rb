# frozen_string_literal: true

require_relative "test_helper"

class RegistryTest < Minitest::Test
  def test_load_merges_and_later_keys_override
    Feelings.load(fixture_path("feelings.yml"))
    Feelings.load(fixture_path("feelings_extra.yml"))

    assert_equal "something that needs a reply today", Feelings[:urgent]
    assert_equal "an unsolicited commercial email", Feelings[:spam]
    assert_equal({ invitation: "an updated invitation description" }, Feelings[:kinds])
  end

  def test_registered_values_are_frozen
    Feelings.load(fixture_path("feelings.yml"))
    assert Feelings[:spam].frozen?
    assert Feelings[:kinds].frozen?
    assert Feelings[:kinds][:invitation].frozen?
  end

  def test_unknown_key_returns_nil
    assert_nil Feelings[:nonexistent]
  end

  def test_register_merges_a_plain_ruby_hash
    Feelings.register(spam: "spam email", kinds: { invitation: "an invitation" })

    assert_equal "spam email", Feelings[:spam]
    assert_equal({ invitation: "an invitation" }, Feelings[:kinds])
  end

  def test_register_values_are_frozen
    Feelings.register(kinds: { invitation: "an invitation" })

    assert Feelings[:kinds].frozen?
    assert Feelings[:kinds][:invitation].frozen?
  end

  def test_register_and_load_merge_together_later_call_wins
    Feelings.register(spam: "registered spam description")
    Feelings.load(fixture_path("feelings.yml"))

    assert_equal "an unsolicited commercial email", Feelings[:spam]

    Feelings.register(spam: "registered again")
    assert_equal "registered again", Feelings[:spam]
  end

  def test_constructs_work_with_empty_registry_and_no_config_file
    stub = RecordingJudge.new
    Feelings.judge = stub

    assert Feelings("mail").like?("urgent")
    assert stub.last_questions
  end

  def test_require_feelings_does_not_load_yaml
    root = File.expand_path("..", __dir__)
    result = system(
      { "BUNDLE_GEMFILE" => File.join(root, "Gemfile") },
      "bundle", "exec", "ruby", "-Ilib", "-e",
      "require 'feelings'; exit(defined?(YAML) ? 1 : 0)",
      chdir: root
    )
    assert result, "expected `require \"feelings\"` to leave YAML unloaded"
  end

  def test_structured_hash_description_is_passed_into_instructions
    Feelings.load(fixture_path("shaped.yml"))

    stub = RecordingJudge.new
    Feelings.judge = stub
    Feelings("mail").like?(:shaped)

    question = stub.last_questions.values.first
    assert_equal "friendly", question["instructions"][:tone]
    assert_equal "billing", question["instructions"][:topic]
  end

  class RecordingJudge
    attr_reader :last_questions

    def call(state:, questions:)
      @last_questions = questions
      questions.each_with_object({}) { |(id, _), h| h[id] = { noul: 0.9, probabilities: {}, model: "rec" } }
    end
  end
end
