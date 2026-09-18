# frozen_string_literal: true

module Feelings
  # Holds registered label sets and descriptions, loaded from YAML or from
  # plain Ruby. Keys are always symbols; values are either a String
  # description or a Hash label set (Symbol => description).
  class Registry
    def initialize
      @data = {}
    end

    def load(path)
      require "yaml"

      loaded = YAML.safe_load(File.read(path), permitted_classes: [Symbol], aliases: true)
      loaded ||= {}
      raise ArgumentError, "registry file must contain a mapping, got #{loaded.class}" unless loaded.is_a?(Hash)

      merge!(loaded)
    end

    def register(hash)
      raise ArgumentError, "register expects a Hash, got #{hash.class}" unless hash.is_a?(Hash)

      merge!(hash)
    end

    def [](key)
      deep_freeze(@data[key.to_sym])
    end

    def to_h
      deep_freeze(@data.dup)
    end

    def reset!
      @data = {}
      self
    end

    private

    def merge!(hash)
      @data = @data.merge(symbolize(hash))
      self
    end

    def symbolize(value)
      case value
      when Hash
        value.each_with_object({}) { |(k, v), h| h[k.to_s.to_sym] = symbolize(v) }
      when Array
        value.map { |v| symbolize(v) }
      else
        value
      end
    end

    def deep_freeze(value)
      case value
      when Hash
        value.each_value { |v| deep_freeze(v) }
        value.freeze
      when Array
        value.each { |v| deep_freeze(v) }
        value.freeze
      else
        value.freeze
      end
    end
  end
end
