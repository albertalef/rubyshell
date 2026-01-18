module RubyShell
  class CommandError < StandardError
    def initialize(command:, stdout: "", stderr: "", status: "", message: nil)
      @command = command
      @stdout = stdout
      @stderr = stderr
      @status = status

      super(message || (stderr.empty? ? stdout : stderr))
    end
  end
end
