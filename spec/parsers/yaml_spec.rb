# frozen_string_literal: true

require_relative "../../lib/rubyshell/parsers/yaml"

RSpec.describe RubyShell::Parsers::Yaml do
  around(:example) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "Methods" do
    describe "#parse" do
      context "when the stdout is valid yaml" do
        def subject_method
          sh.printf("name: Ruby\nversion: 3.0".quoted, _parse: :yaml)
        end

        it "returns a hash" do
          expect(subject_method).to eq({ "name" => "Ruby", "version" => 3.0 })
        end
      end

      context "when the stdout is nested yaml" do
        def subject_method
          sh.printf("database:\n  host: localhost\n  port: 5432".quoted, _parse: :yaml)
        end

        it "returns a nested hash" do
          expect(subject_method).to eq({ "database" => { "host" => "localhost", "port" => 5432 } })
        end
      end

      context "when the stdout is yaml with array" do
        def subject_method
          sh.printf("items:\n  - one\n  - two\n  - three".quoted, _parse: :yaml)
        end

        it "returns a hash with array" do
          expect(subject_method).to eq({ "items" => %w[one two three] })
        end
      end

      context "when the stdout is empty yaml" do
        def subject_method
          sh.echo("", _parse: :yaml)
        end

        it "returns nil" do
          expect(subject_method).to be_nil
        end
      end

      context "when the stdout is invalid yaml" do
        def subject_method
          sh.printf("key: [invalid".quoted, _parse: :yaml)
        end

        it "raises an error" do
          expect { subject_method }.to raise_error(Psych::SyntaxError)
        end
      end
    end
  end
end
