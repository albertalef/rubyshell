# frozen_string_literal: true

RSpec.describe RubyShell do
  around(:example) do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  after do
    RubyShell::EnvProxy.set({})
  end

  describe "RubyShell.env" do
    context "when setting a variable with string key" do
      before { RubyShell.env["GLOBAL_VAR"] = "global_value" }

      it "makes the variable available to commands" do
        expect(sh.printenv("GLOBAL_VAR")).to eq("global_value")
      end
    end

    context "when setting a variable with symbol key" do
      before { RubyShell.env[:SYMBOL_GLOBAL] = "symbol_value" }

      it "converts key to string and makes it available" do
        expect(sh.printenv("SYMBOL_GLOBAL")).to eq("symbol_value")
      end
    end

    context "when getting a variable with symbol key" do
      before { RubyShell.env["STRING_KEY"] = "the_value" }

      it "retrieves the value using symbol" do
        expect(RubyShell.env[:STRING_KEY]).to eq("the_value")
      end
    end

    context "when multiple global variables are set" do
      before do
        RubyShell.env["VAR_A"] = "a"
        RubyShell.env["VAR_B"] = "b"
      end

      it "makes all variables available" do
        expect(sh.printenv("VAR_A")).to eq("a")
        expect(sh.printenv("VAR_B")).to eq("b")
      end
    end
  end

  describe "RubyShell.config" do
    context "when setting env via config" do
      before { RubyShell.config(env: { "CONFIG_VAR" => "config_value" }) }

      it "sets global environment variables" do
        expect(sh.printenv("CONFIG_VAR")).to eq("config_value")
      end
    end
  end

  describe "sh block with env" do
    context "when passing env to sh block" do
      def subject_call
        sh(env: { "BLOCK_LEVEL" => "block_value" }) do
          printenv("BLOCK_LEVEL")
        end
      end

      it "makes variables available within the block" do
        expect(subject_call).to eq("block_value")
      end
    end
  end

  describe "environment variable precedence" do
    context "when command _env overrides global env" do
      before { RubyShell.env["OVERRIDE_VAR"] = "global" }

      def subject_call
        sh.printenv("OVERRIDE_VAR", _env: { "OVERRIDE_VAR" => "command" })
      end

      it "uses command-level value" do
        expect(subject_call).to eq("command")
      end
    end

    context "when command _env adds to global env" do
      before { RubyShell.env["GLOBAL_ONLY"] = "from_global" }

      def subject_call
        sh.printenv("GLOBAL_ONLY", _env: { "CMD_ONLY" => "from_cmd" })
      end

      it "preserves global variables" do
        expect(subject_call).to eq("from_global")
      end
    end
  end

  describe "_env option" do
    context "when passing a single environment variable" do
      def subject_call
        sh.printenv("MY_VAR", _env: { "MY_VAR" => "hello" })
      end

      it "makes the variable available to the command" do
        expect(subject_call).to eq("hello")
      end
    end

    context "when passing multiple environment variables" do
      let(:var1) { sh.printenv("VAR1", _env: { "VAR1" => "foo", "VAR2" => "bar" }) }
      let(:var2) { sh.printenv("VAR2", _env: { "VAR1" => "foo", "VAR2" => "bar" }) }

      it "makes the first variable available" do
        expect(var1).to eq("foo")
      end

      it "makes the second variable available" do
        expect(var2).to eq("bar")
      end
    end

    context "when using symbol keys" do
      def subject_call
        sh.printenv("SYMBOL_VAR", _env: { SYMBOL_VAR: "works" })
      end

      it "converts symbol keys to strings" do
        expect(subject_call).to eq("works")
      end
    end

    context "when _env is not provided" do
      def subject_call
        sh.printenv("PATH")
      end

      it "uses the default environment" do
        expect(subject_call).not_to be_empty
      end
    end

    context "when using inside a sh block" do
      def subject_call
        sh do
          printenv("BLOCK_VAR", _env: { "BLOCK_VAR" => "inside_block" })
        end
      end

      it "works within block form" do
        expect(subject_call).to eq("inside_block")
      end
    end
  end
end
