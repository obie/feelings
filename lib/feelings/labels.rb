# frozen_string_literal: true

module Feelings
  # Resolves and validates label sets used by most_like/pick/match.
  module Labels
    module_function

    def resolve(labels)
      case labels
      when Symbol
        registered = Feelings[labels]
        raise UnknownLabel, "no registered label set for #{labels.inspect}" if registered.nil?

        resolve(registered)
      when Hash
        labels.each_with_object({}) do |(key, description), hash|
          symbol = key.to_sym
          hash[symbol] = description.nil? ? description_for(symbol) : description
        end
      when Array
        labels.each_with_object({}) { |key, hash| hash[key.to_sym] = description_for(key.to_sym) }
      else
        raise BadLabels, "labels must be a Symbol, Hash, or Array, got #{labels.class}"
      end
    end

    def description_for(symbol)
      registered = Feelings[symbol]
      return registered if registered.is_a?(String) || registered.is_a?(Hash)

      humanize(symbol)
    end

    def humanize(symbol)
      symbol.to_s.tr("_", " ")
    end

    def validate!(labels)
      unless labels.is_a?(Hash) && labels.size.between?(2, 255)
        raise BadLabels, "labels must have 2..255 entries, got #{labels.is_a?(Hash) ? labels.size : labels.class}"
      end

      if labels.keys.all? { |key| key.to_s =~ /\A\d+\z/ }
        raise BadLabels, "labels must not be numeric-only symbols"
      end

      labels
    end
  end
end
