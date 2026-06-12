# frozen_string_literal: true

RSpec.describe RubyShell::RemoteExecutor do
  let(:ssh_host) { "testuser@localhost" }
  let(:ssh_key) { File.expand_path("../test_key", __dir__) }
  let(:ssh_options) { { port: 2222, key: ssh_key } }

  before(:all) do
    ssh_available = system(
      "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=2",
      "-p", "2222", "-i", File.expand_path("../test_key", __dir__),
      "testuser@localhost", "echo ok",
      out: File::NULL, err: File::NULL
    )

    unless ssh_available
      skip "SSH server not available (run: docker run -d --name ssh-server -p 2222:2222 " \
           "-e USER_NAME=testuser -e PUBLIC_KEY=\"$(cat test_key.pub)\" " \
           "lscr.io/linuxserver/openssh-server:latest)"
    end
  end

  describe "Basic Remote Execution" do
    context "when executing a single command" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) { echo("hello") }
      end

      it "returns the command output" do
        expect(subject_call).to eq("hello")
      end

      it "returns a StringResult" do
        expect(subject_call).to be_a(RubyShell::Results::StringResult)
      end
    end

    context "when executing multiple commands" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          echo("first")
          echo("second")
        end
      end

      it "returns the last command result" do
        expect(subject_call).to eq("second")
      end
    end

    context "when executing a command with arguments" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) { echo("-n", "no newline") }
      end

      it "passes arguments correctly" do
        expect(subject_call).to eq("no newline")
      end
    end
  end

  describe "Remote cd" do
    context "when changing directory" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          cd("/tmp")
          pwd
        end
      end

      it "persists across commands" do
        expect(subject_call).to eq("/tmp")
      end
    end

    context "when changing directory multiple times" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          cd("/tmp")
          cd("/")
          pwd
        end
      end

      it "tracks the latest directory" do
        expect(subject_call).to eq("/")
      end
    end
  end

  describe "Remote sh" do
    context "when using sh() to call a hyphenated command" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          sh("wl-copy", "test data")
          sh("wl-paste")
        end
      end

      it "executes remotely instead of locally" do
        expect(subject_call).to eq("test data")
      end
    end
  end

  describe "Remote cd with special paths" do
    context "when path contains spaces" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          sh("mkdir", "-p", "'/tmp/ruby shell test'")
          cd("/tmp/ruby shell test")
          pwd
        end
      end

      after do
        sh.remote(ssh_host, **ssh_options) do
          sh("rm", "-rf", "'/tmp/ruby shell test'")
        end
      end

      it "handles spaces in path" do
        expect(subject_call).to eq("/tmp/ruby shell test")
      end
    end
  end

  describe "Host Parsing" do
    context "when host includes user@" do
      before do
        ssh = instance_double(RubyShell::SSH)
        allow(RubyShell::SSH).to receive(:new).and_return(ssh)
        allow(ssh).to receive(:execute).and_return(RubyShell::SSH::Result.new("ok", "", 0))
        allow(ssh).to receive(:close)

        sh.remote("deploy@example.com", **ssh_options) { echo("test") }
      end

      it "parses user and host correctly" do
        expect(RubyShell::SSH).to have_received(:new).with("example.com", hash_including(user: "deploy"))
      end
    end

    context "when host has no user@" do
      before do
        ssh = instance_double(RubyShell::SSH)
        allow(RubyShell::SSH).to receive(:new).and_return(ssh)
        allow(ssh).to receive(:execute).and_return(RubyShell::SSH::Result.new("ok", "", 0))
        allow(ssh).to receive(:close)

        sh.remote("example.com", **ssh_options) { echo("test") }
      end

      it "defaults user to ENV['USER']" do
        expect(RubyShell::SSH).to have_received(:new).with("example.com", hash_including(user: ENV.fetch("USER", nil)))
      end
    end
  end

  describe "Error Handling" do
    context "when a command fails" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) { ls("/nonexistent_path_for_test") }
      end

      it "raises CommandError" do
        expect { subject_call }.to raise_error(RubyShell::CommandError)
      end

      it "includes stderr in the error message" do
        expect { subject_call }.to raise_error(RubyShell::CommandError, /No such file or directory/)
      end
    end

    context "when a command fails mid-block" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          echo("before")
          ls("/nonexistent_path_for_test")
          echo("after")
        end
      end

      it "raises and stops execution" do
        expect { subject_call }.to raise_error(RubyShell::CommandError)
      end
    end
  end

  describe "Result Metadata" do
    context "when inspecting result metadata" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) { echo("meta") }
      end

      it "includes remote flag" do
        expect(subject_call.metadata[:remote]).to be true
      end

      it "includes host" do
        expect(subject_call.metadata[:host]).to eq(ssh_host)
      end

      it "includes the command" do
        expect(subject_call.metadata[:command]).to eq("echo meta")
      end

      it "includes exit status" do
        expect(subject_call.metadata[:exit_status].to_i).to eq(0)
      end

      it "includes a status object with success?" do
        expect(subject_call.metadata[:exit_status].success?).to be true
      end
    end
  end

  describe "Connection Lifecycle" do
    context "when the block completes normally" do
      let(:ssh) { instance_double(RubyShell::SSH) }

      before do
        allow(RubyShell::SSH).to receive(:new).and_return(ssh)
        allow(ssh).to receive(:execute).and_return(RubyShell::SSH::Result.new("ok", "", 0))
        allow(ssh).to receive(:close)

        sh.remote(ssh_host, **ssh_options) { echo("test") }
      end

      it "closes the connection" do
        expect(ssh).to have_received(:close)
      end
    end

    context "when the block raises an error" do
      let(:ssh) { instance_double(RubyShell::SSH) }

      before do
        allow(RubyShell::SSH).to receive(:new).and_return(ssh)
        allow(ssh).to receive(:execute).and_return(RubyShell::SSH::Result.new("", "error", 1))
        allow(ssh).to receive(:close)

        begin
          sh.remote(ssh_host, **ssh_options) { ls("/nonexistent") }
        rescue RubyShell::CommandError
          # expected
        end
      end

      it "still closes the connection" do
        expect(ssh).to have_received(:close)
      end
    end
  end

  describe "Remote chain" do
    context "when using chain with pipe" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          chain { echo("hello world") | wc("-w") }
        end
      end

      it "executes the chain remotely" do
        expect(subject_call.strip).to eq("2")
      end

      it "returns a StringResult" do
        expect(subject_call).to be_a(RubyShell::Results::StringResult)
      end
    end

    context "when using chain with redirect" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          chain { echo("chain test") > "/tmp/rubyshell_chain_test" }
          cat("/tmp/rubyshell_chain_test")
        end
      end

      after do
        sh.remote(ssh_host, **ssh_options) do
          rm("-f", "/tmp/rubyshell_chain_test")
        end
      end

      it "writes and reads via chain" do
        expect(subject_call).to eq("chain test")
      end
    end

    context "when using chain with multiple pipes" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          chain { echo("hello") | cat | cat }
        end
      end

      it "pipes through all commands" do
        expect(subject_call).to eq("hello")
      end
    end
  end

  describe "Remote debug" do
    let(:log_output) { [] }
    let(:logger) { double("Logger", info: nil) }

    before do
      allow(logger).to receive(:info) { |msg| log_output << msg }
      allow(RubyShell).to receive(:logger).and_return(logger)
    end

    after do
      RubyShell.debug = false
    end

    context "when debug is enabled" do
      def subject_call
        sh.remote(ssh_host, **ssh_options, debug: true) { echo("debug test") }
      end

      it "returns the command output" do
        expect(subject_call).to eq("debug test")
      end

      it "logs the command executed" do
        subject_call

        expect(log_output.join).to include("Executed: echo debug test")
      end

      it "logs the host" do
        subject_call

        expect(log_output.join).to include("Host: #{ssh_host}")
      end

      it "logs the port" do
        subject_call

        expect(log_output.join).to include("Port: 2222")
      end

      it "logs the duration" do
        subject_call

        expect(log_output.join).to match(/Duration: \d+\.\d+s/)
      end

      it "logs the exit code" do
        subject_call

        expect(log_output.join).to include("Exit code: 0")
      end

      it "logs the stdout" do
        subject_call

        expect(log_output.join).to include('Stdout: "debug test"')
      end
    end

    context "when debug is not enabled" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) { echo("no debug") }
      end

      it "does not log anything" do
        subject_call

        expect(log_output).to be_empty
      end
    end

    context "when debug is enabled with chain" do
      def subject_call
        sh.remote(ssh_host, **ssh_options, debug: true) do
          chain { echo("debug chain") | wc("-w") }
        end
      end

      it "logs the chained command" do
        subject_call

        expect(log_output.join).to include("Executed: echo debug chain | wc -w")
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
  end

  describe "Integration" do
    context "when creating and listing files" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          cd("/tmp")
          touch("rubyshell_test_file")
          ls("rubyshell_test_file")
        end
      end

      after do
        sh.remote(ssh_host, **ssh_options) do
          rm("-f", "/tmp/rubyshell_test_file")
        end
      end

      it "creates and finds the file" do
        expect(subject_call).to eq("rubyshell_test_file")
      end
    end

    context "when using multiple remote blocks sequentially" do
      def subject_call
        sh.remote(ssh_host, **ssh_options) do
          touch("/tmp/rubyshell_multi_test")
        end

        sh.remote(ssh_host, **ssh_options) do
          ls("/tmp/rubyshell_multi_test")
        end
      end

      after do
        sh.remote(ssh_host, **ssh_options) do
          rm("-f", "/tmp/rubyshell_multi_test")
        end
      end

      it "each block gets an independent connection" do
        expect(subject_call).to eq("/tmp/rubyshell_multi_test")
      end
    end
  end
end
