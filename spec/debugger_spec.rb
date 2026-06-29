# frozen_string_literal: true

RSpec.describe RubyShell::Debugger do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  RSpec.shared_examples "a logged command" do |expected_output|
    it "returns the command output" do
      expect(subject_method).to eq(expected_output)
    end

    it "logs the command executed" do
      subject_method

      expect(log_output.join).to include("Executed: echo #{expected_output}")
    end

    it "logs the duration" do
      subject_method

      expect(log_output.join).to match(/Duration: \d+\.\d+s/)
    end

    it "logs the pid" do
      subject_method

      expect(log_output.join).to match(/Pid: \d+/)
    end

    it "logs the exit code" do
      subject_method

      expect(log_output.join).to include("Exit code: 0")
    end

    it "logs the stdout" do
      subject_method

      expect(log_output.join).to include("Stdout: \"#{expected_output}\"")
    end

    it "logs the stderr" do
      subject_method

      expect(log_output.join).to include("Stderr: \"\"")
    end
  end

  RSpec.shared_examples "a silent command" do
    it "returns the command output" do
      expect(subject_method).to eq("hello")
    end

    it "does not log anything" do
      subject_method
      expect(log_output).to be_empty
    end
  end

  describe ".run_wrapper" do
    let(:log_output) { [] }
    let(:logger) { double("Logger", info: nil) }

    before do
      allow(logger).to receive(:info) { |msg| log_output << msg }
      allow(RubyShell).to receive(:logger).and_return(logger)
    end

    after { RubyShell.debug = false }

    context "when debug mode is disabled" do
      def subject_method
        sh.echo("hello")
      end
      it_behaves_like "a silent command"
    end

    context "when debug mode is enabled via block" do
      def subject_method
        sh(debug: true) { echo("hello") }
      end
      it_behaves_like "a logged command", "hello"
    end

    context "when debug mode is enabled via command option" do
      def subject_method
        sh.echo("hello", _debug: true)
      end

      def run_failed_debug_command
        sh.ruby("-e", "\"STDERR.write(%q{bad}); exit 1\"", _debug: true)
      rescue RubyShell::CommandError
        nil
      end

      def rescued_failed_debug_command
        sh.ruby("-e", "\"STDOUT.write(%q{out}); STDERR.write(%q{bad}); exit 1\"", _debug: true)
        nil
      rescue RubyShell::CommandError => e
        e
      end

      it_behaves_like "a logged command", "hello"

      it "reraises failed commands" do
        expect do
          sh.ruby("-e", "\"STDERR.write(%q{bad}); exit 1\"", _debug: true)
        end.to raise_error(RubyShell::CommandError)
      end

      it "logs failed command exit code before reraising" do
        run_failed_debug_command
        expect(log_output.join).to include("Exit code: 1")
      end

      it "logs failed command stdout before reraising" do
        run_failed_debug_command
        expect(log_output.join).to include("Stdout: \"\"")
      end

      it "logs failed command stderr before reraising" do
        run_failed_debug_command
        expect(log_output.join).to include("Stderr: \"bad\"")
      end

      it "keeps the rescued error type available" do
        expect(rescued_failed_debug_command).to be_a(RubyShell::CommandError)
      end

      it "keeps the rescued error command available" do
        expect(rescued_failed_debug_command.command.to_s).to include("STDOUT.write")
      end

      it "keeps the rescued error stdout available" do
        expect(rescued_failed_debug_command.stdout).to eq("out")
      end

      it "keeps the rescued error stderr available" do
        expect(rescued_failed_debug_command.stderr).to eq("bad")
      end

      it "keeps the rescued error status available" do
        expect(rescued_failed_debug_command.status.exitstatus).to eq(1)
      end
    end

    context "when debug mode is enabled globally" do
      before { RubyShell.debug = true }

      context "when command is used as a method" do
        def subject_method
          sh.echo("world")
        end
        it_behaves_like "a logged command", "world"
      end

      context "when command is executed in a block" do
        def subject_method
          sh { echo("world") }
        end
        it_behaves_like "a logged command", "world"
      end
    end
  end
end