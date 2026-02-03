# frozen_string_literal: true

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
end
