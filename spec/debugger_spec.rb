# frozen_string_literal: true

RSpec.describe RubyShell::Debugger do
  around(:example) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe ".run_wrapper" do
    let(:log_output) { [] }
    let(:logger) { double("Logger", info: nil) }

    before do
      allow(logger).to receive(:info) { |msg| log_output << msg }
      allow(RubyShell).to receive(:logger).and_return(logger)
    end

    after do
      RubyShell.debug = false
    end

    context "when debug mode is disabled" do
      def subject_method
        sh.echo("hello")
      end

      it "returns the command output" do
        expect(subject_method).to eq("hello")
      end

      it "does not log anything" do
        subject_method

        expect(log_output).to be_empty
      end
    end

    context "when debug mode is enabled via block" do
      def subject_method
        sh(debug: true) { echo("hello") }
      end

      it "returns the command output" do
        expect(subject_method).to eq("hello")
      end

      it "logs the command executed" do
        subject_method

        expect(log_output).to include("Executed: echo hello")
      end

      it "logs the duration" do
        subject_method

        expect(log_output.find { |msg| msg.match?(/Duration: \d+\.\d+s/) }).not_to be_nil
      end

      it "logs the pid" do
        subject_method

        expect(log_output.find { |msg| msg.match?(/Pid: \d+/) }).not_to be_nil
      end

      it "logs the exit code" do
        subject_method

        expect(log_output).to include("  Exit code: 0")
      end

      it "logs the stdout" do
        subject_method

        expect(log_output).to include('  Stdout: "hello"')
      end
    end

    context "when debug mode is enabled via command option" do
      def subject_method
        sh.echo("hello", _debug: true)
      end

      it "returns the command output" do
        expect(subject_method).to eq("hello")
      end

      it "logs the command executed" do
        subject_method

        expect(log_output).to include("Executed: echo hello")
      end

      it "logs the duration" do
        subject_method

        expect(log_output.find { |msg| msg.match?(/Duration: \d+\.\d+s/) }).not_to be_nil
      end

      it "logs the pid" do
        subject_method

        expect(log_output.find { |msg| msg.match?(/Pid: \d+/) }).not_to be_nil
      end

      it "logs the exit code" do
        subject_method

        expect(log_output).to include("  Exit code: 0")
      end

      it "logs the stdout" do
        subject_method

        expect(log_output).to include('  Stdout: "hello"')
      end
    end

    context "when debug mode is enabled globally" do
      before { RubyShell.debug = true }

      def subject_method
        sh.echo("world")
      end

      it "returns the command output" do
        expect(subject_method).to eq("world")
      end

      it "logs the command executed" do
        subject_method

        expect(log_output).to include("Executed: echo world")
      end

      it "logs the duration" do
        subject_method

        expect(log_output.find { |msg| msg.match?(/Duration: \d+\.\d+s/) }).not_to be_nil
      end

      it "logs the pid" do
        subject_method

        expect(log_output.find { |msg| msg.match?(/Pid: \d+/) }).not_to be_nil
      end

      it "logs the exit code" do
        subject_method

        expect(log_output).to include("  Exit code: 0")
      end

      it "logs the stdout" do
        subject_method

        expect(log_output).to include('  Stdout: "world"')
      end
    end
  end
end
