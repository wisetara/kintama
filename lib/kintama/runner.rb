module Kintama
  class Runner

    def self.default
      Verbose.new(*Kintama.default_context.subcontexts)
    end

    class Base
      def initialize(*contexts)
        @contexts = contexts
      end

      def run(colour=$stdin.tty?)
        @colour = colour
        @test_count = 0
        @contexts.each do |c|
          @current_indent = -1
          c.run(self)
          puts if c != @contexts.last
        end
        show_results
        passed?
      end

      def context_started(context); end
      def context_finished(context); end
      def test_started(test)
        @test_count += 1
      end
      def test_finished(test); end

      def passed?
        failures.empty?
      end

      def failures
        @contexts.map { |c| c.failures }.flatten
      end

      def test_summary
        "#{@test_count} tests, #{failures.length} failures"
      end

      def show_results
        puts
        puts test_summary
        puts "\n" + failure_messages.join("\n\n") if failures.any?
      end

      def failure_messages
        x = 0
        failures.map do |test|
          x += 1
          "#{x}) #{test.full_name}:\n  #{test.failure_message}"
        end
      end
    end

    class Inline < Base
      def test_finished(test)
        print(test.passed? ? "." : "F")
      end

      def show_results
        puts
        super
      end
    end

    class Verbose < Base
      INDENT = "  "

      def initialize(*contexts)
        super
        @current_indent = -1
      end

      def indent
        INDENT * @current_indent
      end

      def context_started(context)
        @current_indent += 1
        print indent + context.name + "\n" if context.name
      end

      def context_finished(context)
        @current_indent -= 1
      end

      def test_started(test)
        super
        print indent + INDENT + test.name + ": " unless @colour
      end

      def test_finished(test)
        if @colour
          test_name = indent + INDENT + test.name
          if test.passed?
            print green(test_name)
          else
            print red(test_name)
          end
        end
        print(test.passed? ? "." : "F") unless @colour
        puts
      end

      private

      def color(text, color_code)
        "#{color_code}#{text}\e[0m"
      end

      def green(text)
        color(text, "\e[32m")
      end

      def red(text)
        color(text, "\e[31m")
      end
    end

  end
end