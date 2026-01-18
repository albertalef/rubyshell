# frozen_string_literal: true

require "tmpdir"
require "debug"

RSpec.describe RubyShell do
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
        expect { subject_call }.to raise_error(RubyShell::CommandError)
      end
    end

    context "when execute a command and get a not 0 exit code" do
      def subject_call
        sh { ls("notexistingfolder") }
      end

      it "retuns a Command Execution Error" do
        expect { subject_call }.to raise_error(RubyShell::CommandError)
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
        expect { subject_call }.to raise_error(RubyShell::CommandError)
      end
    end
  end

  describe "Validating Command Class" do
    context "when hash arg value has is not a TrueClass" do
      let(:subject_instance) { RubyShell::Command.new("example", firstparam: "Short Phrase") }

      it "returns the correct shell command" do
        expect(subject_instance.to_shell).to eq("example --firstparam 'Short Phrase'")
      end
    end
  end

  describe "Validating Executor Module" do
    context "when extending module" do
      def subject_call
        extend RubyShell::Executor # rubocop:disable Layout/EmptyLinesAfterModuleInclusion

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
