
# Deals with opening and parsing a configfile
# Also provides some utility methods to determine which is the currently active config or if a certain option was provided
module TortillaConfig

  # Minimum options required. If any of them is not given, croak
  REQUIRED_OPTS = [:testlink_server,:dev_key,:prefix]

  def open_and_parse(conf)
    begin
      file = File.open(conf, 'r')
      config_hash = {}
      file.each_line do |line|
        # Disobey comments starting with “#”
        if (line.lstrip).index('#') == 0
          next
        end

        # And disobey empty lines
        # (not really needed due to last if-statement … just for show-off)
        if line.lstrip.rstrip.eql? ""
          next
        end

        # Now, start reading the interesting lines …
        if line.include?('=')
          key, value = line.split('=')
          if value.include?(',') # Assume multiple values => array
            value = value.split(',')

            # remove any newlines
            value.each do |val|
              i = value.index(val)
              value[i].gsub!(/\n/,'')
            end
          else
            value = value.lstrip.rstrip
          end
          config_hash = config_hash.merge({key.downcase.lstrip.rstrip.to_sym => value})

          #config_hash = config_hash.merge({"#{key.downcase.lstrip.rstrip}" => value})
        end
      end
      file.close
    rescue Exception => e
      puts 'An error occured while attempting to read the config file:'
      if e.class == Errno::ENOENT
        puts "No config exists or found at ~/.qa-doccer.conf"
        raise e
      else
        raise e
      end
    end


    # Validation
    # all required opts present?
    self.validate(config_hash)
    config_hash[:name] = conf
    expose_public(config_hash)
    return @config = ::OpenStruct.new(config_hash)
  end
  module_function :open_and_parse

  # A key 'public' can be given
  # which indicates all the options which will be made public to the environment with the value given earlier in the config
  # Public in the config is a string consisting of one or more options to publicize
  # eg, in the configfile:
  # public = option1
  # => [option1]
  # => ENV[OPTION1]
  # public = option1,option2,option3
  # => Array
  # => ["option1", "option2","options3"]
  def self.expose_public(hash)
    if hash.has_key?(:public)
      public = []
      case hash[:public].class.to_s
        when /String/
          public = hash[:public].to_a
        when /Array/
          hash[:public].each  {|option| public << option.gsub(' ','')  }
        else
          raise RuntimeError,"I just don't know what to do with myself, this type of COnfig IS ALL WRONG (expected string or Array)'"
      end
      #$log.debug("Exposing keys:#{ public.inspect}")
      # Each listed key in public, set as an ENV variable with the value from the config
      public.each { |key| ENV[key.to_s.upcase]  = hash[key]  }
    else  # No public options defined
      #$log.debug("No public options defined, not exposing anything.")
    end # has key public?
  end

  # The currently loaded/active config
  def active_config
    @config
  end
  module_function :active_config

  def has_option?(option)
    if @config.send(option.to_sym).nil?
      return false
    else
      return true
    end
  end
  module_function :has_option?

  # Compare given opts vs required opts.
  def self.validate(config_hash)
    missing = (REQUIRED_OPTS - config_hash.keys)
    raise ArgumentError,"Missing required options in config: #{missing} " if missing.length > 0

    # Activated keys, but nil/empty values?
    config_hash.each_pair do |key,val|
      raise ArgumentError,"Invalid config value for key: #{key} " if (val.nil? || val.empty?)
    end

  end
end
