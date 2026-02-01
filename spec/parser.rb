require_relative "../lib/rubyshell/parsers/json"

RSpec.describe RubyShell::Parser do # rubocop:disable Metrics/BlockLength
  around(:example) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe 'Methods' do
    describe '#parse' do
      context 'when parser file exists' do
        def subject_method
          sh.echo("{'Ruby': 'Shell'}", _parse: :json)
        end

        it 'returns the correct result' do
        expect(subject_method).to eq({
            "Ruby": "Shell"
          })
        end
      end
    end
  end
end
