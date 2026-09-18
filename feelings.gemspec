# frozen_string_literal: true

require_relative "lib/feelings/version"

Gem::Specification.new do |spec|
  spec.name = "feelings"
  spec.version = Feelings::VERSION
  spec.authors = ["Obie Fernandez"]
  spec.email = ["obiefernandez@gmail.com"]

  spec.summary = "Probabilistic conditionals for Ruby: Feelings(message).like?(\"genuinely urgent\")"
  spec.description = <<~DESC.strip.gsub(/\n/, " ")
    feelings brings the feels construct from the Probably language to Ruby. A decision
    model judges how well a description fits a value, and feelings turns that into
    conditionals, semantic match, bounded loops, chaos sampling, and replayable tapes.
    Descriptions and label sets can live in YAML. Works with any judge; ruby_decision_model
    is the default.
  DESC
  spec.homepage = "https://github.com/obie/feelings"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby_decision_model", "~> 0.1"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.metadata["rubygems_mfa_required"] = "true"
end
