module Config

  REQUIRED_OPTS = ['testlink_server','dev_key','prefix']



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

          config_hash = config_hash.merge({"#{key.downcase.lstrip.rstrip}" => value})
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
    return @config = ::OpenStruct.new(config_hash)
  end
  module_function :open_and_parse

  def active_config
    @config
  end
  module_function :active_config


  def self.validate(config_hash)
    missing = (REQUIRED_OPTS - config_hash.keys)
    raise ArgumentError,"Missing required options in config: #{missing} " if missing.length > 0

    # Activated keys, but nil/empty values?
    config_hash.each_pair do |key,val|
      raise ArgumentError,"Invalid config value for key: #{key} " if (val.nil? || val.empty?)
    end

  end
end
