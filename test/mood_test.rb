
class MoodBranchTest < Minitest::Test
  def setup
    Feelings.reset!
  end

  def test_maybe_branch_turns_bands_on_without_source_introspection
    Feelings.judge = Feelings::Judges::Stub.new("urgent" => 0.6)
    block = eval('proc { |mood| mood.yes { :yes }; mood.maybe { :maybe }; mood.no { :no } }') # rubocop:disable Style/EvalWithLocation
    assert_equal :maybe, Feelings("mail").like("urgent", &block)
    assert_equal :yes, Feelings("mail").like("urgent") { |mood| mood.yes { :yes }; mood.no { :no } }
  end

  def test_confidence_keyword_is_not_treated_as_a_question
    Feelings.judge = Feelings::Judges::Stub.new("spam" => 0.9, kinds: :invitation)
    Feelings.register(kinds: { invitation: "an invitation", pitch: "a pitch" })
    result = Feelings("mail").like?(spam: "spam", kind: :kinds, confidence: 0.5)
    assert_equal({ spam: true, kind: :invitation }, result)
  end

  def test_same_question_with_different_floors_judges_once
    stub = Feelings::Judges::Stub.new("spam" => 0.6)
    Feelings.judge = stub
    f = Feelings("mail")
    f.like?("spam")
    f.like?("spam", at_least: 0.8)
    assert_equal 1, stub.calls.size
  end
end
