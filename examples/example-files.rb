#!/usr/bin/env ruby

require "rubyshell"
require "securerandom"

sh do
  mkdir "files"

  cd "files" do
    5.times { |i| echo "#{SecureRandom.alphanumeric(5)}>>#{i}.txt" }

    number_of_files = chain { ls | wc("-l") }.strip

    puts "Number of files: #{number_of_files}"

    ls.each_line do |file|
      puts cat(file)
    end
  end

  rm "-rf files"
end

# Running:
#
# ❯ ./examples/example-files.rb
#
# Number of files: 5
# YzN5S
# igEiz
# AU5fy
# rRlDW
# O6NCB
