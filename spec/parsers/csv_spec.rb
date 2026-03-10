# frozen_string_literal: true

require_relative "../../lib/rubyshell/parsers/csv"

RSpec.describe RubyShell::Parsers::Csv do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "Methods" do
    describe "#parse" do
      context "when the stdout is valid csv" do
        def subject_method
          sh.printf("name,age\nAlice,30\nBob,25".quoted, _parse: :csv)
        end

        it "returns an array of arrays" do
          expect(subject_method).to eq([%w[name age], %w[Alice 30], %w[Bob 25]])
        end
      end

      context "when the stdout is a single row csv" do
        def subject_method
          sh.echo("a,b,c", _parse: :csv)
        end

        it "returns a single row array" do
          expect(subject_method).to eq([%w[a b c]])
        end
      end

      context "when the stdout is empty csv" do
        def subject_method
          sh.echo("", _parse: :csv)
        end

        it "returns an empty array" do
          expect(subject_method).to eq([])
        end
      end

      context "when the stdout has fields with commas" do
        def subject_method
          sh.printf('a,"b,c",d'.quoted, _parse: :csv)
        end

        it "parses quoted fields correctly" do
          expect(subject_method).to eq([["a", "b,c", "d"]])
        end
      end
    end
  end
end
