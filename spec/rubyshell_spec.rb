# frozen_string_literal: true

require "tmpdir"
require "debug"

RSpec.describe RubyShell do # rubocop:disable Metrics/BlockLength
  around(:example) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "Validating Returns" do
    context "when trying to create a new folder and print the path" do
      before do
        sh do
          mkdir "example-folder"

          cd "example-folder"
        end
      end

      def subject_call
        sh { pwd }
      end

      it "retuns the correct filepath" do
        expect(subject_call).to include("/example-folder")
      end

      it "creates a new folder named example-folder" do
        subject_call

        expect(Dir["../*"]).to eq(["../example-folder"])
      end
    end

    context "when trying to execute a command that does not exists" do
      def subject_call
        sh { nonexistingcommand }
      end

      it "retuns a Command Execution Error" do
        expect do
          subject_call
        end.to raise_error(RubyShell::CommandError, /No such file or directory - nonexistingcommand/)
      end
    end

    context "when execute a command and get a not 0 exit code" do
      def subject_call
        sh { ls("notexistingfolder") }
      end

      it "retuns a Command Execution Error" do
        expect do
          subject_call
        end.to raise_error(RubyShell::CommandError,
                           /ls: cannot access 'notexistingfolder': No such file or directory/)
      end
    end

    context "when execute directly the command" do
      def subject_call
        sh.mkdir "example-folder"
        sh.cd "example-folder"
        sh.pwd
      end

      it "retuns the correct filepath" do
        expect(subject_call).to include("/example-folder")
      end

      it "creates a new folder named example-folder" do
        subject_call

        expect(Dir["../*"]).to eq(["../example-folder"])
      end
    end

    context "when execute outside a tty" do
      before { allow($stdin).to receive(:isatty).and_return(false) }

      it "returns the raw string for cleaner IRB output" do
        expect(sh.echo("hello\nworld".quoted).inspect).to eq('"hello\nworld"')
      end
    end

    context "when execution in a tty" do
      before { allow($stdin).to receive(:isatty).and_return(true) }

      it "returns the raw string for cleaner IRB output" do
        expect(sh.echo("hello\nworld".quoted).inspect).to eq("hello\nworld")
      end
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

  describe "Validating Command Class" do
    context "when hash arg value has is not a TrueClass" do
      let(:subject_instance) { RubyShell::Command.new("example", firstparam: "Short Phrase") }

      it "returns the correct shell command" do
        expect(subject_instance.to_shell).to eq("example --firstparam \"Short Phrase\"")
      end
    end

    context "when pass stgin in args as string" do
      def subject_call
        sh do
          wc("-l", _stdin: "3\n3\n")
        end
      end

      it "returns an string" do
        expect(subject_call.strip).to eq("2")
      end
    end

    context "when pass stgin in args as command" do
      def subject_call
        sh do
          wc("-l", _stdin: echo!("3\n3\n".quoted))
        end
      end

      it "returns an string" do
        expect(subject_call.strip).to eq("2")
      end
    end

    context "when pass hash arg with array as value" do
      def subject_call
        sh do
          sed!(e: %w[one two three]).to_shell
        end
      end

      it "returns the correct command" do
        expect(subject_call).to eq("sed -e \"one\" -e \"two\" -e \"three\"")
      end
    end

    context "when call the command with a bang" do
      def subject_call
        sh do
          echo! "oi", e: %w[a b], _stdin: "oi"
        end
      end

      it "returns a command class" do
        expect(subject_call).to be_a_instance_of(RubyShell::Command)
      end

      it "returns the correct shell" do
        expect(subject_call.to_shell).to eq("echo oi -e \"a\" -e \"b\"")
      end

      it "preserves the arguments" do
        expect(subject_call.options).to include(
          _stdin: "oi"
        )
      end
    end
  end

  describe "Validating Executor Module" do
    context "whe using sh method to execute a command as param" do
      def subject_call
        sh("mkdir", "example-folder")
        sh("cd", "example-folder")
        sh("pwd")
      end

      it "retuns the correct filepath" do
        expect(subject_call).to include("/example-folder")
      end

      it "creates a new folder named example-folder" do
        subject_call

        expect(Dir["../*"]).to eq(["../example-folder"])
      end
    end

    context "whe using sh method to execute a command as param inside another sh block" do
      def subject_call
        sh do
          sh("mkdir", "example-folder")
          sh("cd", "example-folder")
          sh("pwd")
        end
      end

      it "retuns the correct filepath" do
        expect(subject_call).to include("/example-folder")
      end

      it "creates a new folder named example-folder" do
        subject_call

        expect(Dir["../*"]).to eq(["../example-folder"])
      end
    end

    context "when extending module" do
      def subject_call
        extend RubyShell::Executor

        mkdir "example-folder"
        cd "example-folder"
        pwd
      end

      it "retuns the correct filepath" do
        expect(subject_call).to include("/example-folder")
      end

      it "creates a new folder named example-folder" do
        subject_call

        expect(Dir["../*"]).to eq(["../example-folder"])
      end
    end
  end

  it "has a version number" do
    expect(RubyShell::VERSION).not_to be nil
  end
end
