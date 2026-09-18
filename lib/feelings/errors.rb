# frozen_string_literal: true

module Feelings
  class Error < StandardError; end

  class NoJudge < Error; end

  class JudgeError < Error; end

  class LoopLimit < Error; end

  class ReplayMismatch < Error; end

  class InvalidDistribution < Error; end

  class UnknownLabel < Error; end

  class BadLabels < Error; end

  class UnknownState < Error; end
end
