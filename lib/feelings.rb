# frozen_string_literal: true

require "ruby_decision_model"

require_relative "feelings/version"
require_relative "feelings/errors"
require_relative "feelings/registry"
require_relative "feelings/distribution"
require_relative "feelings/labels"
require_relative "feelings/state"
require_relative "feelings/questions"
require_relative "feelings/mood"
require_relative "feelings/pick"
require_relative "feelings/tape"
require_relative "feelings/match_builder"
require_relative "feelings/block_introspection"
require_relative "feelings/engine"
require_relative "feelings/about"
require_relative "feelings/judges/stub"
require_relative "feelings/judges/decision_model"

# feelings brings the `feels` construct from the Probably language to Ruby.
# A decision model judges how well a description fits a value, and
# feelings turns that into conditionals, semantic match, bounded loops,
# chaos sampling, and replayable tapes.
module Feelings
  class << self
    def judge=(judge)
      @judge = judge
      @judge_set = true
    end

    def judge
      return @judge if @judge_set

      @judge = Judges::DecisionModel.new(RubyDecisionModel.client)
      @judge_set = true
      @judge
    end

    def with_judge(judge)
      previous = Thread.current[:feelings_judge_override]
      Thread.current[:feelings_judge_override] = judge
      yield
    ensure
      Thread.current[:feelings_judge_override] = previous
    end

    def current_judge
      Thread.current[:feelings_judge_override] || judge
    end

    def random=(source)
      @random = source
    end

    def random
      @random ||= -> { Kernel.rand }
    end

    def load(path)
      registry.load(path)
      registry.to_h
    end

    def register(hash)
      registry.register(hash)
      registry.to_h
    end

    def [](key)
      registry[key]
    end

    def registry
      @registry ||= Registry.new
    end

    def reset!
      @registry = Registry.new
      @judge = nil
      @judge_set = false
      @random = nil
      self
    end

    def chaos
      previous = Thread.current[:feelings_chaos]
      Thread.current[:feelings_chaos] = true
      yield
    ensure
      Thread.current[:feelings_chaos] = previous
    end

    def chaos?
      !!Thread.current[:feelings_chaos]
    end

    def record
      tape = Tape.new
      previous = Thread.current[:feelings_tape]
      Thread.current[:feelings_tape] = tape
      yield
      tape
    ensure
      Thread.current[:feelings_tape] = previous
    end

    def current_tape
      Thread.current[:feelings_tape]
    end

    def replay(tape)
      queue = tape.entries.dup
      previous = Thread.current[:feelings_replay]
      Thread.current[:feelings_replay] = queue
      result = yield
      raise ReplayMismatch, "tape has #{queue.size} unused entries" unless queue.empty?

      result
    ensure
      Thread.current[:feelings_replay] = previous
    end

    def current_replay
      Thread.current[:feelings_replay]
    end

    def while(initial, description, max: 10)
      raise ArgumentError, "max must be between 1 and 50" unless (1..50).cover?(max)

      current = initial
      max.times do
        mood = About.new(current).like(description)
        return current if mood.no?

        current = yield(current)
      end
      raise LoopLimit, "Loop still feels true after #{max} iterations."
    end

    def like?(value, *args, **kwargs)
      About.new(value).like?(*args, **kwargs)
    end

    def like(value, *args, **kwargs, &block)
      About.new(value).like(*args, **kwargs, &block)
    end

    def most_like(value, *args, **kwargs)
      About.new(value).most_like(*args, **kwargs)
    end

    def match(value, *args, **kwargs, &block)
      About.new(value).match(*args, **kwargs, &block)
    end
  end
end

module Kernel
  def Feelings(value)
    Feelings::About.new(value)
  end
  private :Feelings
end

require_relative "feelings/railtie" if defined?(Rails::Railtie)
