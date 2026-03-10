# frozen_string_literal: true

RSpec.describe RubyShell do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "Validating Executable" do
    context 'when using "new" command' do
      def subject_method
        sh do
          rubyshell "new", "testfile".quoted
        end
      end

      it "creates the correct file" do
        subject_method

        expect(sh.ls.chomp).to eq("testfile.rb")
      end

      it "creates a file with correct permissions" do
        subject_method

        expect(sh.ls("-l", "testfile.rb").split.first).to eq("-rwxr-xr-x")
      end
    end

    context 'when using "new" command without a filename' do
      def subject_method
        sh do
          rubyshell "new"
        end
      end

      it "creates the correct file" do
        subject_method

        expect(sh.ls.chomp).to eq("new_script.rb")
      end
    end
  end
end
