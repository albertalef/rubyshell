# frozen_string_literal: true

RSpec.describe RubyShell do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
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
end
