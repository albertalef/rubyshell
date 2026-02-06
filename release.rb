#!/usr/bin/env ruby
# frozen_string_literal: true

require "rubyshell"

sh do
  gem "bump", version: "minor"

  bundle "exec", "rake", "release"
end
