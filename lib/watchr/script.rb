module Watchr
  class Script
    Rule = Struct.new(:pattern, :action)

    # eval context
    #class API
    #end

    def initialize(file = StringIO.new)
      @file  = file
      @rules = []
      @default_action = lambda {}
      parse!
    end

    def watch(pattern, &action)
      @rules << Rule.new(pattern, action || @default_action)
    end

    def default_action(&action)
      @default_action = action
    end

    def parse!
      Watchr.debug('loading script file %s' % @file.to_s.inspect)

      @rules.clear
      instance_eval(@file.read)
    end

    def action_for(path)
      rule = rule_for(path)
      data = path.to_s.match(rule.pattern)
      lambda { rule.action.call(data) }
    end

    def patterns
      #@rules.every.pattern
      @rules.map {|r| r.pattern }
    end

    def path
      Pathname(@file.to_s)
    end

    private

    def rule_for(path)
      path = Pathname(path).expand_path.relative_path_from(Pathname(Dir.pwd)).to_s
      @rules.reverse.detect {|rule| path.match(rule.pattern) }
    end
  end
end
