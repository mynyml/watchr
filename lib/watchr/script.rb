module Watchr

  # A script object wraps a script file, and is used by a controller.
  #
  # @example
  #
  #     path   = Pathname.new('specs.watchr')
  #     script = Watchr::Script.new(path)
  #
  class Script

    # @private
    DEFAULT_EVENT_TYPE = :modified

    # Convenience type. Provides clearer and simpler access to rule properties.
    #
    # @example
    #
    #     rule = script.watch('lib/.*\.rb') { 'ohaie' }
    #     rule.pattern      #=> 'lib/.*\.rb'
    #     rule.action.call  #=> 'ohaie'
    #
    Rule = Struct.new(:pattern, :event_type, :action)

    # Script file evaluation context
    #
    # Script files are evaluated in the context of an instance of this class so
    # that they get a clearly defined set of methods to work with. In other
    # words, it is the user script's API.
    #
    # @private
    class EvalContext #:nodoc:

      def initialize(script)
        @__script = script
      end

      # Delegated to script
      def default_action(&action)
        @__script.default_action(&action)
      end

      # Delegated to script
      def watch(*args, &block)
        @__script.watch(*args, &block)
      end

      # Reload script
      def reload
        @__script.parse!
      end
    end

    # EvalContext instance
    #
    # @example
    #
    #     script.ec.watch('pattern') { }
    #     script.ec.reload
    #
    # @return [EvalContext]
    #
    attr_reader :ec

    # Defined rules
    #
    # @return [Rule]
    #   all rules defined with `#watch` calls
    #
    attr_reader :rules

    # Create a Script object for script at `path`
    #
    # @param [Pathname] path
    #   the path to the script
    #
    def initialize(path = nil)
      @path = path
      @rules = []
      @default_action = Proc.new {}
      @ec = EvalContext.new(self)
    end

    # Main script API method. Builds a new rule, binding a pattern to an action.
    #
    # Whenever a file is saved that matches a rule's `pattern`, its
    # corresponding `action` is triggered.
    #
    # Patterns can be either a Regexp or a string. Because they always
    # represent paths however, it's simpler to use strings. But remember to use
    # single quotes (not double quotes), otherwise escape sequences will be
    # parsed (for example `"foo/bar\.rb" #=> "foo/bar.rb"`, notice "\." becomes
    # "."), and won't be interpreted as the regexp you expect.
    #
    # Also note that patterns will be matched against relative paths (relative
    # to current working directory).
    #
    # Actions, the blocks passed to `watch`, receive a `MatchData` object as
    # argument. It will be populated with the whole matched string ( `md[0]` )
    # as well as individual backreferences ( `md[1..n]` ). See `MatchData#[]`
    # documentation for more details.
    #
    # @example
    #
    #     # in script file
    #     watch( 'test/test_.*\.rb' )  {|md| system("ruby #{md[0]}") }
    #     watch( 'lib/(.*)\.rb' )      {|md| system("ruby test/test_#{md[1]}.rb") }
    #
    # With these two rules, watchr will run any test file whenever it is itself
    # changed (first rule), and will also run a corresponding test file
    # whenever a lib file is changed (second rule).
    #
    # @param [#match] pattern
    #   pattern to match targetted paths
    #
    # @param [Symbol] event_type
    #   rule will only match events of this type. Accepted types are
    #   `:accessed`, `:modified`, `:changed`, `:delete` and `nil` (any), where
    #   the first three correspond to atime, mtime and ctime respectively.
    #   Defaults to `:modified`.
    #
    # @yield
    #   action to trigger
    #
    # @return [Rule]
    #
    def watch(pattern, event_type = DEFAULT_EVENT_TYPE, &action)
      @rules << Rule.new(pattern, event_type, action || @default_action)
      @rules.last
    end

    # Convenience method. Define a default action to be triggered when a rule
    # has none specified. When called without a block, acts as a getter and
    # returns stored default_action
    #
    # @example
    #
    #     # in script file
    #
    #     default_action { system('rake --silent yard') }
    #
    #     watch( 'lib/.*\.rb'  )
    #     watch( 'README.md'   )
    #     watch( 'TODO.txt'    )
    #     watch( 'LICENSE'     )
    #
    #     # is equivalent to:
    #
    #     watch( 'lib/.*\.rb'  ) { system('rake --silent yard') }
    #     watch( 'README.md'   ) { system('rake --silent yard') }
    #     watch( 'TODO.txt'    ) { system('rake --silent yard') }
    #     watch( 'LICENSE'     ) { system('rake --silent yard') }
    #
    # @return [Proc]
    #   default action
    #
    def default_action(&action)
      @default_action = action if action
      @default_action
    end

    # Reset script state
    def reset
      @rules = []
      @default_action = Proc.new {}
    end

    # Eval content of script file.
    #
    # @todo improve ENOENT error handling
    def parse!
      return unless @path
      reset
      @ec.instance_eval(@path.read, @path.to_s)
    rescue Errno::ENOENT
      sleep(0.3) #enough?
      retry
    ensure
      Watchr.debug('loaded script file %s' % @path.to_s.inspect)
    end

    # Find an action corresponding to a path and event type. The returned
    # action is actually a wrapper around the rule's action, with the
    # match_data prepopulated.
    #
    # @example
    #
    #     script.watch( 'test/test_.*\.rb' ) {|md| "ruby #{md[0]}" }
    #     script.action_for('test/test_watchr.rb').call #=> "ruby test/test_watchr.rb"
    #
    # @param [Pathname, String] path
    #   find action that corresponds to this path.
    #
    # @param [Symbol] event_type
    #   find action only if rule's event is of this type.
    #
    # @return [Proc]
    #   action, preparsed and ready to be called
    #
    def action_for(path, event_type = DEFAULT_EVENT_TYPE)
      path = rel_path(path).to_s
      rule = rules_for(path).detect {|rule| rule.event_type.nil? || rule.event_type == event_type }
      if rule
        data = path.match(rule.pattern)
        lambda { rule.action.call(data) }
      else
        lambda {}
      end
    end

    # Collection of all patterns defined in script.
    #
    # @return [Array<String,Regexp>]
    #   all defined patterns
    #
    def patterns
      #@rules.every.pattern
      @rules.map {|r| r.pattern }
    end

    # Path to the script file corresponding to this object
    #
    # @return [Pathname]
    #   absolute path to script file
    #
    def path
      @path && Pathname(@path.respond_to?(:to_path) ? @path.to_path : @path.to_s).expand_path
    end

    private

    # Rules corresponding to a given path, in reversed order of precedence
    # (latest one is most inportant).
    #
    # @param [Pathname, String] path
    #   path to look up rule for
    #
    # @return [Array<Rule>]
    #   rules corresponding to `path`
    #
    def rules_for(path)
      @rules.reverse.select {|rule| path.match(rule.pattern) }
    end

    # Make a path relative to current working directory.
    #
    # @param [Pathname, String] path
    #   absolute or relative path
    #
    # @return [Pathname]
    #   relative path, from current working directory.
    #
    def rel_path(path)
      Pathname(path).expand_path.relative_path_from(Pathname(Dir.pwd))
    end
  end
end
