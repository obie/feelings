# frozen_string_literal: true

require_relative "test_helper"

class StateTest < Minitest::Test
  def test_string_passes_through
    assert_equal "hello", Feelings::State.resolve("hello")
  end

  def test_numeric_passes_through
    assert_equal 42, Feelings::State.resolve(42)
    assert_equal 3.14, Feelings::State.resolve(3.14)
  end

  def test_booleans_and_nil_pass_through
    assert_equal true, Feelings::State.resolve(true)
    assert_equal false, Feelings::State.resolve(false)
    assert_nil Feelings::State.resolve(nil)
  end

  def test_hash_keys_are_stringified_and_values_resolved
    resolved = Feelings::State.resolve(name: "Ada", age: 30)
    assert_equal({ "name" => "Ada", "age" => 30 }, resolved)
  end

  def test_array_elements_are_resolved
    resolved = Feelings::State.resolve(["a", 1, { key: "v" }])
    assert_equal ["a", 1, { "key" => "v" }], resolved
  end

  def test_nested_hash_array_hash_resolution
    input = { items: [{ label: "x" }, { label: "y", tags: ["a", "b"] }] }
    resolved = Feelings::State.resolve(input)
    expected = { "items" => [{ "label" => "x" }, { "label" => "y", "tags" => ["a", "b"] }] }
    assert_equal expected, resolved
  end

  def test_to_feelings_state_used_as_is_with_no_further_resolution
    custom = Class.new do
      def to_feelings_state
        { untouched: :symbol_stays }
      end
    end.new

    resolved = Feelings::State.resolve(custom)
    assert_equal({ untouched: :symbol_stays }, resolved)
  end

  def test_to_feelings_state_nested_inside_an_array
    custom = Class.new do
      def to_feelings_state
        "custom state"
      end
    end.new

    resolved = Feelings::State.resolve(["plain", custom])
    assert_equal ["plain", "custom state"], resolved
  end

  def test_as_json_fallback
    custom = Class.new do
      def as_json
        "json state"
      end
    end.new

    assert_equal "json state", Feelings::State.resolve(custom)
  end

  def test_as_json_fallback_result_is_recursively_resolved
    custom = Class.new do
      def as_json
        { name: "Ada", nested: { tag: "value" } }
      end
    end.new

    resolved = Feelings::State.resolve(custom)
    assert_equal({ "name" => "Ada", "nested" => { "tag" => "value" } }, resolved)
  end

  def test_unsupported_object_raises_with_class_name
    klass = Class.new
    object = klass.new

    error = assert_raises(Feelings::UnknownState) { Feelings::State.resolve(object) }
    assert_includes error.message, object.class.name.to_s
    assert_includes error.message, "to_feelings_state"
  end

  def test_unsupported_anonymous_object_raises_with_actual_class_name
    foo = Class.new
    Object.const_set(:Foo, foo)
    object = foo.new

    error = assert_raises(Feelings::UnknownState) { Feelings::State.resolve(object) }
    assert_includes error.message, "Foo"
  ensure
    Object.send(:remove_const, :Foo) if Object.const_defined?(:Foo)
  end

  def test_about_wrapper_uses_resolved_state_on_the_wire
    stub = RecordingJudge.new
    Feelings.judge = stub

    custom = Class.new do
      def to_feelings_state
        { "custom" => "state" }
      end
    end.new

    Feelings(custom).like?("anything")

    assert_equal({ "custom" => "state" }, stub.last_state["value"])
  end

  def test_about_value_returns_the_raw_original_object
    custom = Struct.new(:x) do
      def to_feelings_state
        "resolved"
      end
    end.new(1)

    wrapper = Feelings(custom)
    assert_same custom, wrapper.value
  end

  class RecordingJudge
    attr_reader :last_state

    def call(state:, questions:)
      @last_state = state
      questions.each_with_object({}) { |(id, _), h| h[id] = { noul: 0.9, probabilities: {}, model: "rec" } }
    end
  end
end
