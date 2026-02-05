# frozen_string_literal: true

require_relative "../lib/rubyshell/parsers/json"

RSpec.describe RubyShell do
  around(:example) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "Validating Chains" do
    context "when counting files in current folder" do
      def subject_call
        sh do
          chain { ls | wc("-l") }
        end
      end

      it "returns an string" do
        expect(subject_call.strip).to eq("0")
      end
    end

    context "when counting files in current folder using bang pattern" do
      def subject_call
        sh do
          (ls! | wc!("-l")).exec
        end
      end

      it "returns an string" do
        expect(subject_call.strip).to eq("0")
      end
    end

    context "when counting files in current folder" do
      def subject_call
        sh do
          chain { ls | wc("-l") }
        end
      end

      it "returns an string" do
        expect(subject_call.strip).to eq("0")
      end
    end

    context "when using string as operator pair" do
      def subject_call
        sh do
          chain { echo("Pretty Content") >> "testfile.txt" }

          cat "testfile.txt"
        end
      end

      it "returns an string" do
        expect(subject_call).to eq("Pretty Content")
      end
    end

    context "when execute a command and get a not 0 exit code" do
      def subject_call
        sh do
          chain { ls("notexistingfolder") }
        end
      end

      it "retuns a Command Execution Error" do
        expect do
          subject_call
        end.to raise_error(RubyShell::CommandError,
                           /ls: cannot access 'notexistingfolder': No such file or directory/)
      end
    end
  end

  describe "Chain with Options" do
    context "when chain is called with options" do
      def subject_call
        sh do
          chain({}) { echo("with options") }
        end
      end

      it "executes successfully" do
        expect(subject_call).to eq("with options")
      end
    end

    context "when chain is called with parse option" do
      def subject_call
        sh do
          chain(parse: :json) { echo('{"key": "value"}') }
        end
      end

      it "parses the result as JSON" do
        expect(subject_call).to eq({ key: "value" })
      end
    end

    context "when chain is called with debug option" do
      let(:log_output) { [] }
      let(:logger) { double("Logger", info: nil) }

      before do
        allow(logger).to receive(:info) { |msg| log_output << msg }
        allow(RubyShell).to receive(:logger).and_return(logger)
      end

      after do
        RubyShell.debug = false
      end

      def subject_call
        sh do
          chain(debug: true) { echo("debug chain") }
        end
      end

      it "enables debug for the chain" do
        subject_call

        expect(log_output.join).to include("Executed: echo debug chain")
      end

      it "logs the duration" do
        subject_call

        expect(log_output.join).to match(/Duration: \d+\.\d+s/)
      end

      it "logs the exit code" do
        subject_call

        expect(log_output.join).to include("Exit code: 0")
      end
    end

    context "when chainer executes with debug enabled via sh block" do
      let(:log_output) { [] }
      let(:logger) { double("Logger", info: nil) }

      before do
        allow(logger).to receive(:info) { |msg| log_output << msg }
        allow(RubyShell).to receive(:logger).and_return(logger)
      end

      after do
        RubyShell.debug = false
      end

      def subject_call
        sh(debug: true) do
          chain { ls | wc("-l") }
        end
      end

      it "logs the chained command" do
        subject_call

        expect(log_output.join).to include("Executed: ls | wc -l")
      end

      it "logs the duration" do
        subject_call

        expect(log_output.join).to match(/Duration: \d+\.\d+s/)
      end
    end
  end
end
