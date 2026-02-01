require_relative "../../lib/rubyshell/parsers/json"

RSpec.describe RubyShell::Parsers::Json do
  around(:example) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "Methods" do
    describe "#parse" do
      context "when the stdout is a json" do
        def subject_method
          sh.echo("{\"Ruby\": \"Shell\"}", _parse: :json)
        end

        it "returns the correct result" do
          expect(subject_method).to eq({ Ruby: "Shell" })
        end
      end

      context "when the stdout is not a json" do
        def subject_method
          sh.echo("test", _parse: :json)
        end

        it "returns the correct result" do
          expect { subject_method }.to raise_error(JSON::ParserError)
        end
      end

      context "when the stdout is a empty json" do
        def subject_method
          sh.echo("{}", _parse: :json)
        end

        it "returns the correct result" do
          expect(subject_method).to eq({})
        end
      end
    end
  end
end
