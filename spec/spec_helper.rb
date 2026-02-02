# frozen_string_literal: true

require "tmpdir"
require "debug"
require_relative "../lib/rubyshell"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    module Warning
      def self.warn(msg)
        return if msg =~ /conflicting chdir during another chdir block/

        super
      end
    end
  end
end
