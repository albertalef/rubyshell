# frozen_string_literal: true

module RubyShell
  class ParallelExecutor
    def initialize(options = {})
      @commands = []
      @options = options

      @queue = Queue.new
    end

    def shared_settings
      %i[env debug]
    end

    def settings
      @options.select { shared_settings.include?(_1.to_sym) }.transform_keys { :"_#{_1}" }
    end

    def _evaluate(&block)
      instance_exec(&block)

      self
    end

    def _run
      @commands.each do |command|
        Thread.new do
          @queue << begin
            command.exec
          rescue StandardError => e
            e
          end
        end
      end

      Enumerator.new do |y|
        @commands.size.times { y << @queue.pop }
      end
    end

    def chain(options = {}, &block)
      @commands << RubyShell::ChainContext.new(settings.merge(options)).instance_exec(&block)
    end

    def sh(command, *args)
      method_missing(command, *args)
    end

    def method_missing(method_name, *args, **kwargs)
      command = RubyShell::Command.new(method_name.to_s.gsub(/!$/, ""), *args, **settings, **kwargs)

      @commands << command
    end

    def respond_to_missing?(_name, _include_private)
      false
    end
  end
end
