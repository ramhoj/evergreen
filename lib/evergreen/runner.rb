module Evergreen
  class Runner
    attr_reader :spec

    def self.run(root, io=STDOUT)
      runners = Spec.all(root).map { |spec| new(spec) }
      runners.each do |runner|
        if runner.passed?
          io.print '.'
        else
          io.print 'F'
        end
      end
      io.puts ""

      runners.each do |runner|
        io.puts runner.failure_message unless runner.passed?
      end
      runners.all? { |runner| runner.passed? }
    end

    def initialize(spec)
      @spec = spec
    end

    def name
      spec.name
    end

    def passed?
      failed_examples.empty?
    end

    def failure_message
      failed_examples.map do |row|
        msg = []
        msg << "  Failed: #{row['name']}"
        msg << "    #{row['message']}"
        msg << "    in #{row['trace']['fileName']}:#{row['trace']['lineNumber']}" if row['trace']
        msg.join("\n")
      end.join("\n\n")
    end

  protected

    def failed_examples
      results.select { |row| !row['passed'] }
    end

    def results
      @results ||= begin
        session = Capybara::Session.new(:selenium, Evergreen.application(spec.root, :selenium))
        session.visit(spec.url)
        JSON.parse(session.evaluate_script('Evergreen.getResults()'))
      end
    end

  end
end




