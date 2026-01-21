module RubyShell
  module Sanitizer
    SAFE_REGEX = /"/
    # Inspired on https://github.com/ruby/shellwords/blob/master/lib/shellwords.rb
    def self.sanitize_to_shell(string)
      return unless string

      raise ArgumentError, "NUL character" if string.index("\0")

      string = string.to_s.dup

      if string.match?(/\A(["'])(.*)\1\z/m) # starts+ends with same quote
        q = string[0] # " or '
        inner = string[1..-2] # content without the outer quotes

        inner.gsub!(SAFE_REGEX) { |ch| "\\#{ch}" } # escape matches

        string.replace("\"#{inner}\"")
      else
        string.gsub!(SAFE_REGEX) { |ch| "\\#{ch}" }
      end

      string.gsub!("\n", "'\n'")

      string
    end
  end
end
