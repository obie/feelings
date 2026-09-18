# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "feelings"
require "minitest/autorun"

module Minitest
  class Test
    def setup
      Feelings.reset!
    end

    def teardown
      Feelings.reset!
    end

    def fixture_path(name)
      File.join(__dir__, "fixtures", name)
    end
  end
end
