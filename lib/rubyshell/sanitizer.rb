# frozen_string_literal: true

module RubyShell
  module Sanitizer
    SAFE_REGEX = /"/.freeze

    # Inspired on https://github.com/ruby/shellwords/blob/master/lib/shellwords.rb
    def self.sanitize_to_shell(string) # rubocop:disable Metrics/MethodLength
      return unless string

      raise ArgumentError, "NUL character" if string.index("\0")

      string = string.to_s.dup

      if string.match?(/\A(["'])(.*)\1\z/m)
        inner = string[1..-2]

        inner.gsub!(SAFE_REGEX) { |ch| "\\#{ch}" }

        string.replace("\"#{inner}\"")
      else
        string.gsub!(SAFE_REGEX) { |ch| "\\#{ch}" }
      end

      string
    end
  end
end
