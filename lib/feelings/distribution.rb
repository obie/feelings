# frozen_string_literal: true

module Feelings
  # Helpers for turning a probability spread into a normalized distribution
  # and sampling from it, used by Feelings.chaos.
  module Distribution
    TOLERANCE = 0.02

    module_function

    def normalize(probabilities)
      raise InvalidDistribution, "distribution must not be empty" if probabilities.nil? || probabilities.empty?

      floats = probabilities.transform_values(&:to_f)
      sum = floats.values.sum

      if sum.zero?
        even = 1.0 / floats.size
        return floats.transform_values { even }
      end

      unless (sum - 1.0).abs <= TOLERANCE
        raise InvalidDistribution, "distribution sums to #{sum}, expected roughly 1.0"
      end

      floats.transform_values { |v| v / sum }
    end

    def sample(probabilities, draw)
      normalized = normalize(probabilities)
      cumulative = 0.0
      normalized.each do |key, probability|
        cumulative += probability
        return key if draw < cumulative
      end
      normalized.keys.last
    end
  end
end
