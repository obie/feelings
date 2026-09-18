# frozen_string_literal: true

require "json"

module Feelings
  # A recording of every question a judge answered during Feelings.record,
  # replayable later with Feelings.replay so tests never hit a real judge.
  class Tape
    include Enumerable

    Entry = Struct.new(:kind, :value, :question, :answer, :model, :draw, keyword_init: true) do
      def to_h
        super.reject { |_, v| v.nil? }
      end
    end

    attr_reader :entries

    def initialize(entries = [])
      @entries = entries
    end

    def <<(entry)
      entries << entry
      self
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      entries.each(&block)
    end

    def size
      entries.size
    end

    def to_a
      entries.map(&:to_h)
    end

    def to_json(*args)
      JSON.generate(to_a, *args)
    end

    def self.from_json(json)
      raw = JSON.parse(json, symbolize_names: true)
      raise ArgumentError, "tape JSON must be an array" unless raw.is_a?(Array)

      new(raw.map { |hash| Entry.new(**hash) })
    end
  end
end
