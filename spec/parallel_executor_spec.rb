# frozen_string_literal: true

RSpec.describe RubyShell::ParallelExecutor do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  after do
    RubyShell.debug = false
    RubyShell::EnvProxy.set({})
  end

  describe "Basic Parallel Execution" do
    context "when executing multiple commands in parallel" do
      def subject_call
        sh do
          parallel do
            echo("first")
            echo("second")
          end.to_a
        end
      end

      it "returns results for all commands" do
        expect(subject_call.size).to eq(2)
      end

      it "returns StringResult objects" do
        expect(subject_call).to all(be_a(RubyShell::Results::StringResult))
      end

      it "returns the correct values" do
        expect(subject_call).to contain_exactly("first", "second")
      end
    end

    context "when commands complete at different times" do
      def subject_call
        sh do
          parallel do
            bash("-c", "sleep 0.4 && echo SLOW".quoted)
            bash("-c", "echo FAST".quoted)
          end.to_a
        end
      end

      it "returns faster command result first" do
        expect(subject_call.first).to eq("FAST")
      end

      it "returns slower command result last" do
        expect(subject_call.last).to eq("SLOW")
      end
    end

    context "when parallel block returns" do
      def subject_call
        sh do
          parallel do
            echo("test")
          end
        end
      end

      it "returns an Enumerator" do
        expect(subject_call).to be_a(Enumerator)
      end
    end

    context "when parallel block has no commands" do
      def subject_call
        sh do
          parallel {}.to_a # rubocop:disable Lint/EmptyBlock
        end
      end

      it "returns empty array" do
        expect(subject_call).to eq([])
      end
    end

    context "when parallel block has single command" do
      def subject_call
        sh do
          parallel do
            echo("only one")
          end.to_a
        end
      end

      it "returns array with one result" do
        expect(subject_call).to eq(["only one"])
      end
    end
  end

  describe "Parallel with Chain" do
    context "when using chain inside parallel" do
      def subject_call
        sh do
          touch "test.txt"

          parallel do
            chain { ls | wc("-l") }
          end.to_a
        end
      end

      it "executes the chain and returns result" do
        expect(subject_call.first.strip).to eq("1")
      end
    end

    context "when using multiple chains inside parallel" do
      def subject_call
        sh do
          parallel do
            chain { echo("hello") | wc("-c") }
            chain { echo("world") | wc("-c") }
          end.to_a
        end
      end

      it "returns results for all chains" do
        expect(subject_call.size).to eq(2)
      end

      it "returns the correct character counts" do
        expect(subject_call.map { |r| r.strip.to_i }).to contain_exactly(6, 6)
      end
    end

    context "when mixing regular commands and chains in parallel" do
      def subject_call
        sh do
          parallel do
            echo("direct")
            chain { echo("chained") | cat }
          end.to_a
        end
      end

      it "returns results for both" do
        expect(subject_call).to contain_exactly("direct", "chained")
      end
    end
  end

  describe "Parallel Error Handling" do
    context "when a command fails in parallel" do
      def subject_call
        sh do
          parallel do
            ls("nonexistent_folder")
            echo("success")
          end.to_a
        end
      end

      it "returns the correct result" do
        expect(subject_call).to contain_exactly(be_a(RubyShell::CommandError), "success")
      end
    end

    context "when all commands fail in parallel" do
      def subject_call
        sh do
          parallel do
            ls("nonexistent1")
            ls("nonexistent2")
          end.to_a
        end
      end

      it "returns all exceptions" do
        expect(subject_call).to all(be_a(RubyShell::CommandError))
      end
    end

    context "when command does not exist" do
      def subject_call
        sh do
          parallel do
            nonexistentcommand
          end.to_a
        end
      end

      it "returns CommandError" do
        expect(subject_call.first).to be_a(RubyShell::CommandError)
      end
    end
  end

  describe "Parallel with Debug Mode" do
    let(:log_output) { [] }
    let(:logger) { double("Logger", info: nil) }

    before do
      allow(logger).to receive(:info) { |msg| log_output << msg }
      allow(RubyShell).to receive(:logger).and_return(logger)
    end

    context "when debug mode is passed to parallel" do
      def subject_call
        sh do
          parallel(debug: true) do
            echo("test")
          end.to_a
        end
      end

      it "enables debug logging" do
        subject_call

        expect(log_output.join).to include("Executed: echo test")
      end

      it "logs duration" do
        subject_call

        expect(log_output.join).to match(/Duration: \d+\.\d+s/)
      end

      it "logs exit code" do
        subject_call

        expect(log_output.join).to include("Exit code: 0")
      end
    end

    context "when debug mode is enabled on sh block with parallel inside" do
      def subject_call
        sh(debug: true) do
          parallel do
            echo("test")
          end.to_a
        end
      end

      it "logs debug information" do
        subject_call

        expect(log_output.join).to include("Executed: echo test")
      end

      it "logs the stdout" do
        subject_call

        expect(log_output.join).to include('Stdout: "test"')
      end
    end
  end

  describe "Parallel with Environment Variables" do
    context "when global env is set" do
      before { RubyShell.env["PARALLEL_VAR"] = "global_value" }

      def subject_call
        sh do
          parallel do
            printenv("PARALLEL_VAR")
          end.to_a
        end
      end

      it "makes global env available to parallel commands" do
        expect(subject_call.first).to eq("global_value")
      end
    end

    context "when using _env option in parallel commands" do
      def subject_call
        sh do
          parallel do
            printenv("CMD_VAR", _env: { "CMD_VAR" => "cmd_value" })
          end.to_a
        end
      end

      it "applies per-command environment" do
        expect(subject_call.first).to eq("cmd_value")
      end
    end
  end

  describe "Parallel with sh Method" do
    context "when using sh() inside parallel block" do
      def subject_call
        sh do
          parallel do
            sh(:echo, "via sh")
          end.to_a
        end
      end

      it "executes the command" do
        expect(subject_call.first).to eq("via sh")
      end
    end
  end

  describe "Thread Safety" do
    context "when parallel commands use different env values" do
      def subject_call
        sh do
          parallel do
            printenv("TEST_VAR", _env: { "TEST_VAR" => "value1" })
            printenv("TEST_VAR", _env: { "TEST_VAR" => "value2" })
          end.to_a.sort
        end
      end

      it "each command sees its own env value" do
        expect(subject_call).to eq(%w[value1 value2])
      end
    end

    context "when running many commands in parallel" do
      def subject_call
        sh do
          parallel do
            10.times { |i| echo(i.to_s) }
          end.to_a
        end
      end

      it "completes all commands" do
        expect(subject_call.size).to eq(10)
      end

      it "returns all expected values" do
        expect(subject_call.map(&:to_i).sort).to eq((0..9).to_a)
      end
    end
  end

  describe "Integration Tests" do
    context "when using parallel with other operations in sh block" do
      def subject_call
        sh do
          mkdir("test_dir")

          parallel do
            touch("test_dir/file1.txt")
            touch("test_dir/file2.txt")
          end.to_a

          ls("test_dir")
        end
      end

      it "creates files in parallel and lists them" do
        expect(subject_call).to include("file1.txt", "file2.txt")
      end
    end
  end
end
