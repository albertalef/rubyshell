# frozen_string_literal: true

RSpec.describe RubyShell::SSH do
  let(:ssh_key) { File.expand_path("../test_key", __dir__) }

  before(:all) do
    ssh_available = system(
      "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=2",
      "-p", "2222", "-i", File.expand_path("../test_key", __dir__),
      "testuser@localhost", "echo ok",
      out: File::NULL, err: File::NULL
    )

    skip "SSH server not available" unless ssh_available
  end

  describe "#execute" do
    let(:ssh) { described_class.new("localhost", user: "testuser", port: 2222, key: ssh_key) }

    after { ssh.close }

    context "when running a simple command" do
      def subject_call
        ssh.execute("echo hello")
      end

      it "returns stdout" do
        expect(subject_call.stdout).to eq("hello")
      end

      it "returns empty stderr on success" do
        expect(subject_call.stderr).to eq("")
      end

      it "returns exit code 0 on success" do
        expect(subject_call.exit_code).to eq(0)
      end

      it "returns success?" do
        expect(subject_call.success?).to be true
      end
    end

    context "when command writes to stderr" do
      def subject_call
        ssh.execute("echo error >&2")
      end

      it "captures stderr" do
        expect(subject_call.stderr).to eq("error")
      end
    end

    context "when command writes to both stdout and stderr" do
      def subject_call
        ssh.execute("echo out; echo err >&2")
      end

      it "captures stdout" do
        expect(subject_call.stdout).to eq("out")
      end

      it "captures stderr" do
        expect(subject_call.stderr).to eq("err")
      end
    end

    context "when command fails" do
      def subject_call
        ssh.execute("ls /nonexistent_test_path")
      end

      it "returns non-zero exit code" do
        expect(subject_call.exit_code).not_to eq(0)
      end

      it "returns success? false" do
        expect(subject_call.success?).to be false
      end

      it "captures stderr from failed command" do
        expect(subject_call.stderr).to include("No such file or directory")
      end
    end

    context "when command times out" do
      let(:ssh) { described_class.new("localhost", user: "testuser", port: 2222, key: ssh_key, timeout: 1) }

      def subject_call
        ssh.execute("sleep 10")
      end

      it "raises CommandTimeout" do
        expect { subject_call }.to raise_error(RubyShell::SSH::CommandTimeout)
      end

      it "allows per-command timeout override" do
        expect { ssh.execute("sleep 10", timeout: 1) }.to raise_error(RubyShell::SSH::CommandTimeout)
      end
    end

    context "when maintaining shell state between commands" do
      before { ssh.execute("cd /tmp") }

      def subject_call
        ssh.execute("pwd")
      end

      it "persists directory changes" do
        expect(subject_call.stdout).to eq("/tmp")
      end
    end

    context "when executing after stderr output" do
      before { ssh.execute("echo error1 >&2") }

      def subject_call
        ssh.execute("echo clean")
      end

      it "does not leak stderr between commands" do
        expect(subject_call.stderr).to eq("")
      end
    end

    context "when executing after stdout output" do
      before { ssh.execute("echo first") }

      def subject_call
        ssh.execute("echo second")
      end

      it "does not leak stdout between commands" do
        expect(subject_call.stdout).to eq("second")
      end
    end
  end

  describe "Result" do
    let(:ssh) { described_class.new("localhost", user: "testuser", port: 2222, key: ssh_key) }

    after { ssh.close }

    context "when using to_s" do
      def subject_call
        ssh.execute("echo hello")
      end

      it "returns stdout" do
        expect(subject_call.to_s).to eq("hello")
      end
    end

    context "when using output alias" do
      def subject_call
        ssh.execute("echo hello")
      end

      it "returns stdout" do
        expect(subject_call.output).to eq("hello")
      end
    end

    context "when using lines" do
      def subject_call
        ssh.execute("echo -e 'a\nb\nc'")
      end

      it "returns an array of lines" do
        expect(subject_call.lines.map(&:chomp)).to eq(%w[a b c])
      end
    end
  end

  describe "#execute with sh() inside remote block" do
    context "when using sh to call a hyphenated command" do
      def subject_call
        sh.remote("testuser@localhost", port: 2222, key: ssh_key) do
          sh("wl-paste")
        end
      end

      it "executes the command remotely" do
        expect(subject_call).to be_a(RubyShell::Results::StringResult)
      end
    end
  end

  describe "#close" do
    context "when connection was never established" do
      def subject_call
        described_class.allocate.close
      end

      it "does not raise" do
        expect { subject_call }.not_to raise_error
      end
    end

    context "when SSH process already died" do
      def subject_call
        ssh = described_class.new("localhost", user: "testuser", port: 2222, key: ssh_key)
        Process.kill("TERM", ssh.instance_variable_get(:@wait_thread).pid)
        sleep 0.2
        ssh.close
      end

      it "does not raise" do
        expect { subject_call }.not_to raise_error
      end
    end

    context "when called multiple times" do
      def subject_call
        ssh = described_class.new("localhost", user: "testuser", port: 2222, key: ssh_key)
        ssh.close
        ssh.close
      end

      it "does not raise" do
        expect { subject_call }.not_to raise_error
      end
    end
  end

  describe "pipe EOF handling" do
    context "when SSH process dies mid-command" do
      def subject_call
        ssh = described_class.new("localhost", user: "testuser", port: 2222, key: ssh_key, timeout: 5)
        pid = ssh.instance_variable_get(:@wait_thread).pid

        Thread.new do
          sleep 0.3
          Process.kill("TERM", pid)
        end

        start = Time.now

        begin
          ssh.execute("sleep 10")
        rescue RubyShell::SSH::CommandTimeout, Errno::EPIPE, IOError
          # any of these are acceptable
        end

        elapsed = Time.now - start
        ssh.close
        elapsed
      end

      it "returns within timeout instead of hanging" do
        expect(subject_call).to be < 3
      end
    end
  end
end
