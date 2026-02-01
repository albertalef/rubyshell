RSpec.describe RubyShell::Parser do
  around(:example) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "Methods" do
    describe "#parse" do
      context "when parser file exists" do
        def subject_method
          require_relative "../lib/rubyshell/parsers/json"

          sh.echo("{\"Ruby\": \"Shell\"}", _parse: :json)
        end

        it "returns the correct result" do
          expect(subject_method).to eq({
                                         Ruby: "Shell"
                                       })
        end
      end

      context "when parser file not exists" do
        def subject_method
          sh.echo("{\"Ruby\": \"Shell\"}", _parse: :json)
        end

        it "raises an error" do
          expect { subject_method }.to raise_error(RubyShell::Parser::ParserNotFound)
        end
      end
    end
  end
end
