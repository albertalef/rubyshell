# frozen_string_literal: true

require_relative "../lib/rubyshell/error"
require_relative "../lib/rubyshell"

RSpec.describe RubyShell::CommandError do
  let(:command) { "ls -z" }
  let(:stderr)  { "ls: illegal option -- z" }
  let(:status)  { 1 }

  subject(:error) do
    described_class.new(
      command: command,
      stderr: stderr,
      status: status
    )
  end

  describe "#initialize" do
    it "stores the command, stderr, and status" do
      expect(error.command).to eq(command)
      expect(error.status).to eq(status)
    end

    it "uses stderr as the exception message by default" do
      expect(error.message).to eq(stderr)
    end

    it "falls back to stdout if stderr is empty" do
      msg = "Everything is fine"
      err = described_class.new(command: "echo", stdout: msg, stderr: "")
      expect(err.message).to eq(msg)
    end

    it "prioritizes an explicit message if provided" do
      err = described_class.new(command: "x", message: "Custom Overide")
      expect(err.message).to eq("Custom Overide")
    end
  end
end
