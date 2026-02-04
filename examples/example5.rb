#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/rubyshell"

sh(debug: true) do
  results = parallel do
    bash("-lc", "sleep 3; echo C".quoted)
    bash("-lc", "sleep 2; echo B".quoted)
    bash("-lc", "sleep 1; echo A".quoted)
    chain { ls | wc(l: true) }
  end

  puts "Before Print"

  results.each do |a|
    puts a
  end

  puts "After Print"
end
