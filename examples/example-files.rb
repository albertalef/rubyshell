#!/usr/bin/env ruby

require 'rubyshell'
require "securerandom"

sh do
  mkdir "files"

  cd "files" do
    5.times do |i|
      echo "#{SecureRandom.alphanumeric(5)} >> #{i}.txt"
    end

    number_of_files = chain { ls | wc("-l") }.strip

    puts "Number of files: #{number_of_files}"

    ls.each_line do |file|
      puts cat(file)
    end
  end

  rm "-rf files"
end
