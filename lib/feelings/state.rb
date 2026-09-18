# frozen_string_literal: true

module Feelings
  # Resolves an arbitrary Ruby object into the value that gets sent to a
  # judge as wire state. Applied once when Feelings::About wraps a value.
  module State
    module_function

    def resolve(object)
      if object.respond_to?(:to_feelings_state)
        object.to_feelings_state
      elsif object.is_a?(String) || object.is_a?(Numeric) || object == true || object == false || object.nil?
        object
      elsif object.is_a?(Hash)
        object.each_with_object({}) { |(k, v), h| h[k.to_s] = resolve(v) }
      elsif object.is_a?(Array)
        object.map { |v| resolve(v) }
      elsif object.respond_to?(:as_json)
        resolve(object.as_json)
      else
        raise UnknownState,
              "Feelings cannot turn a #{object.class} into state. Define " \
              "#{object.class}#to_feelings_state (return a String, Hash, or Array of the fields " \
              "the question needs) or as_json."
      end
    end
  end
end
