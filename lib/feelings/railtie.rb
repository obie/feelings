# frozen_string_literal: true

module Feelings
  class Railtie < Rails::Railtie
    config.after_initialize do
      config_path = Rails.root.join("config", "feelings.yml")
      Feelings.load(config_path) if File.exist?(config_path)
    end
  end
end
