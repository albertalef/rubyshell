#!/usr/bin/env ruby

require "rubyshell"
require "json"

sh do
  response = JSON.parse(curl("-s", "https://official-joke-api.appspot.com/random_ten"))

  response.each.with_index do |data, i|
    puts " Joke: #{i.next} ".center(30, "-")
    puts "Setup: #{data["setup"]}"
    puts "Punchline: #{data["punchline"]}"
  end

  puts "-" * 30
end

# Running:
#
# ❯ ./examples/example3.rb
#
# ---------- Joke: 1 -----------
# Setup: What do you give a sick lemon?
# Punchline: Lemonaid.
# ---------- Joke: 2 -----------
# Setup: What do you call a bear with no teeth?
# Punchline: A gummy bear!
# ---------- Joke: 3 -----------
# Setup: What type of music do balloons hate?
# Punchline: Pop music!
# ---------- Joke: 4 -----------
# Setup: Why did the cookie go to the doctor?
# Punchline:  Because it was feeling crumbly.
# ---------- Joke: 5 -----------
# Setup: What is the difference between ignorance and apathy?
# Punchline: I don't know and I don't care.
# ---------- Joke: 6 -----------
# Setup: What was the pumpkin’s favorite sport?
# Punchline: Squash.
# ---------- Joke: 7 -----------
# Setup: Why do bananas have to put on sunscreen before they go to the beach?
# Punchline: Because they might peel!
# ---------- Joke: 8 -----------
# Setup: Why did the functions stop calling each other?
# Punchline: Because they had constant arguments.
# ---------- Joke: 9 -----------
# Setup: How did Darth Vader know what Luke was getting for Christmas?
# Punchline: He felt his presents.
# ---------- Joke: 10 ----------
# Setup: An IPv6 packet is walking out of the house.
# Punchline: He goes nowhere.
# ------------------------------
