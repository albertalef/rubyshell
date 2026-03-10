# frozen_string_literal: true

RSpec.describe RubyShell do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "Validating Executor Module" do
    context "when using sh method to execute a command as param" do
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

    context "when using sh method to execute a command as param inside another sh block" do
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
end
