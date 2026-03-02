# frozen_string_literal: true

RSpec.describe RubyShell::CommandError do
  let(:cmd) { "false" }
  let(:error_instance) do
    sh.send(cmd.to_sym)
    raise "sh.#{cmd} did not raise RubyShell::CommandError as expected"
  rescue described_class => e
    e
  end

  describe "Error object API" do
    it "stores the command, stderr, and status" do
      expect(error_instance.command).to eq("false")
      expect(error_instance.status.to_s).to match(/exit 1/)
    end
  end
end
