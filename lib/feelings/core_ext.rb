# frozen_string_literal: true

require_relative "../feelings"

class Object
  def feels_like?(...)
    Feelings(self).like?(...)
  end

  def feels_like(...)
    Feelings(self).like(...)
  end

  def feels_most_like(...)
    Feelings(self).most_like(...)
  end
end
