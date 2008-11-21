
require 'optparse'

module Commander
  class Runner
    
    class Error < StandardError; end
    class InvalidCommandError < Error; end
    
    attr_reader :commands, :options
    
    ##
    # Initialize a new command runner.
    #
    # The command runner essentially manages execution
    # of a commander program. For testing and arbitrary
    # purposes we can specify +input+, +output+, and 
    # +args+ parameters to aid in mock terminal usage etc.
    #
    
    def initialize(input = $stdin, output = $stdout, args = ARGV)
      @input, @output, @args = input, output, args
      @commands, @program, @options = {}, {}, { :help => false }
      parse_global_options # TODO: move to run! so globals can be added... causes an error with @args though
      create_default_commands
    end
    
    ##
    # Run the command parsing and execution process immediately.
    
    def run!
      %w[ name version description ].each { |k| ensure_program_key_set k.to_sym }
      case 
      when options[:help]; get_command(:help).run args_without_command 
      else active_command.run args_without_command
      end
    rescue InvalidCommandError
      @output.puts "Invalid command. Use --help for more information"
    end
    
    ##
    # Assign program information.
    #
    # === Examples:
    #    
    #    # Set data
    #    program :name, 'Commander'
    #    program :version, Commander::VERSION
    #    program :description, 'Commander utility program.'
    #
    #    # Get data
    #    program :name # => 'Commander'
    #
    # === Keys:
    #
    # * :name:           (required) Program name
    # * :version:        (required) Program version triple, ex: '0.0.1'
    # * :description:    (required) Program description
    # * :help_formatter: Defaults to Commander::HelpFormatter::Terminal
    #
    
    def program(key, value = nil)
      @program[key] = value unless value.nil?
      @program[key] if value.nil?
    end
    
    ##
    # Generate a command object instance using a block
    # evaluated with the command as its scope.
    #
    # === Examples:
    #    
    #    command :my_command do |c|
    #      c.when_called do |args|
    #        # Code
    #      end
    #    end
    #
    # === See:
    #
    # * Commander::Command
    # * Commander::Runner#add_command
    #
    
    def command(name, &block)
      command = Commander::Command.new name
      command.instance_eval &block
      add_command command
    end
    
    ##
    # Add a command object to this runner.
    
    def add_command(command)
      @commands[command.name] = command
    end
    
    ##
    # Get a command object if available or nil.
    
    def get_command(name)
      if @commands[name] 
        @commands[name]
      else
        raise InvalidCommandError, "Invalid command '#{name || "nil"}'", caller
      end
    end
    
    ##
    # Get active command within arguments passed to this runner.
    #
    # === Returns:
    #    
    # Commander::Command object or nil
    #
    # === See:
    #
    # * Commander::Runner#parse_global_options
    #
    
    def active_command
      get_command command_name_from_args
    end
    
    ##
    # Attemps to locate command from @args, otherwise nil.
    
    def command_name_from_args 
      @args.find { |arg| arg.match /^[a-z_0-9]+$/i }.to_sym rescue nil
    end
    
    private
    
    ##
    # Creates default commands such as 'help' which is 
    # essentially the same as using the --help switch.
    
    def create_default_commands
      command :help do |c|
        c.syntax = "command help"
        c.description = "Displays help global or sub-command help information."
        c.example "Display global help", "command help"
        c.example "Display help for 'sub-command'", "command help sub-command"
        c.when_called do |args|
          puts 'help was called'
          p args
        end
      end
    end
            
    ##
    # Parse global command options.
    #
    # These options are used by commander itself 
    # as well as allowing your program to specify 
    # global commands such as '--verbose'.
    #
    # TODO: allow 'option' method for global program
    #
    
    def parse_global_options
      opts = OptionParser.new
      opts.on("--help") { @options[:help] = true }
      opts.parse! @args.dup
    rescue OptionParser::InvalidOption
      # Ignore invalid options since options will be further 
      # parsed by our sub commands.
    end
    
    def ensure_program_key_set(key)
      raise Error, "Program #{key} required (use #program method)" unless @program[key]
    end
    
    def args_without_command
      @_args_without_command ||= lambda { args = @args.dup; args.shift; args }.call
    end
        
  end
end