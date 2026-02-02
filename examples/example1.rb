#!/usr/bin/env ruby
# frozen_string_literal: true

require "rubyshell"
require "securerandom"

sh do
  mkdir "-p", "files"

  cd "files" do
    5.times do |i|
      chain do
        echo(SecureRandom.alphanumeric(16)) >> "#{i}.txt"
      end
    end

    puts "Number of Files: #{ls.lines.count}"

    ls.each_line do |filename|
      puts cat(filename)
    end
  end
ensure
  rm "-rf files"
end

# Running:
#
# ❯ ./examples/example1.rb
#
# Number of Files: 5
# o6Kw8KHvWJnLGSeQ
# qkRKcZHqu2Moq1se
# nUPluln9GM1ydtoz
# rkdYsc1RBhkeN1dq
# ZPXZMqzYfyFfjPHF
