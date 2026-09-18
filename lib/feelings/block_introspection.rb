# frozen_string_literal: true

module Feelings
  # Best-effort detection of whether a `like` block declares a `mood.maybe`
  # branch, so the yes/maybe/no bands can be picked before the block runs.
  # Works by reading the block's own source; a block with no readable
  # source (built via eval, or from a file that no longer exists) is
  # treated as not declaring a maybe branch, which keeps the plain 0.5
  # split behavior.
  module BlockIntrospection
    module_function

    def declares_maybe?(block)
      return false unless block

      file, start_line = block.source_location
      return false unless file && start_line && File.readable?(file)

      lines = File.readlines(file)
      return false if start_line > lines.size

      depth = 0
      buffer = +""
      lines[(start_line - 1)..-1].each do |line|
        buffer << line
        depth += line.scan(/\bdo\b|\{/).size
        depth -= line.scan(/\bend\b|\}/).size
        break if depth <= 0
      end

      buffer.match?(/\.maybe\b/)
    rescue StandardError
      false
    end
  end
end
