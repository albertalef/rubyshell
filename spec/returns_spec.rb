# frozen_string_literal: true

RSpec.describe RubyShell do
  around do |example|
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
end
