#!/usr/bin/env ruby
# frozen_string_literal: true

require "rubyshell"
require "securerandom"

sh do
  puts pwd # => /Users/albertalef/projects/rubyshell

  cd "examples"

  puts pwd # => /Users/albertalef/projects/rubyshell/examples
end
