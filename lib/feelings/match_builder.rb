# frozen_string_literal: true

module Feelings
  # Collects on(:key, "description") { ... } and otherwise { ... } branches
  # declared inside a Feelings#match block.
  class MatchBuilder
    Branch = Struct.new(:keys, :block)

    attr_reader :branches, :labels

    def initialize
      @branches = []
      @otherwise = nil
      @labels = {}
    end

    def on(*keys, &block)
      description = keys.last.is_a?(String) ? keys.pop : nil
      symbols = keys.map(&:to_sym)
      symbols.each { |key| @labels[key] = description } unless description.nil?
      @branches << Branch.new(symbols, block)
    end

    def otherwise(&block)
      @otherwise = block if block
      @otherwise
    end

    def branch_for(label)
      branches.find { |branch| branch.keys.include?(label) }
    end
  end
end
