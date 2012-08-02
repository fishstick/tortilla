class TortillaConfig

  attr_reader :config_options
  attr_accessor :db_conn
  # Create a new configuration, or load an existing one by name
  # @param opts [Hash] Initiialisation options
  # @option opts [Symbol] :name Existing config name to load
  def initialize(opts={})
    @db_conn = TortillaDB.instance.configuration
    @default_config =  TortillaDB.instance.defaults.configuration
    # If name given, open an existing config
    @config_options = []

    if opts.has_key?(:name)
      # Name given => attempt to load existing conf
      self.load(opts[:name])
    else
      create_attribute_accessors(@db_conn)
      # No name => assume new/Empty config, make proper attribute accessors anyway
    end
  end



 # There can only ever be one record in default_configuration, so get the first one.
  # Returns the tortillaDb::Configuration entry that is currently the default config
  def find_default_config
    @db_conn.find_by_id(@default_config)
  end
  # Loads the tortillaDb::Configuration entry that is currently the default config
  def load_default_config
    self.load(find_default_config.name)
  end

  # Set self as the default config
  def set_as_default_config
    if self.id.nil?
      puts 'Current configuration is not yet saved, cannot set as default'
    elsif self.id == default_config_id
      puts 'Currently loaded config is already default'
    elsif self.id != default_config_id
      puts 'Saving this one as default'
      @default_config.set_default_configuration(self.id)
    else
      puts 'Something unexpected'
    end


  end


  # Overwrites existing configs wit that name, or creates a new one if it doesn't exist yet
  def create_or_update(opts,update_opts={})
    if self.name # Only save when a name is known
      @db_conn.create_or_update({:name => self.name}.merge(opts),update_opts)
    end
  end


  def create_attribute_accessors(record)
    record.attribute_names.each do |attr_name|
      self.instance_variable_set(('@' + attr_name),record.read_attribute(attr_name)) if record.class == TortillaDB::Configuration # Dont do this for plain/empty db connections
      _mk_updater_method(attr_name)  # make attr_accessor-like method that auto-updates the DB values, too...
      _mk_reader_method(attr_name)  # make attr_reader-like method that auto-updates the DB values, too...
      _add_to_options(attr_name) # Add to the list of config directives so other methods can easily distinguish between 'normal' instance vars and ORM vars
    end
    true
  end

  # Load an existing config by name
  # Does a few important things:
  # * Sets internal instance variables based on each Config attribute
  # * Makes attr-reader and attr-updater methods for each
  # * Adds each attr to a helper array of all options, so other classes can request which options are available (for enumeration, for example)
  # * The attr-updater methods provide an ORM between TortillaConfig and activerecord
  def load(name)
    if (record = open_configuration(name))
      create_attribute_accessors(record)
      puts "Config #{name} loaded..."
      return self
    else
      puts "Something wrong, attempted to load a config but no records were found for that name"
      false
    end
  end




  def list
    @db_conn.all
  end

  def save()
    record = create_config_record
    @db_conn.create_or_update({:name => self.name}.merge(record),record)
  end


  # TODO: FIX!!
  # Delete requires an ID, not a name
  def delete(name = self.name)
    if name.nil? || name.empty?
      puts "No config loaded and no name given"
    else
      @db_conn.delete(name)
    end
  end


  # Create a proper hash of self in order to save
  def create_config_record
    puts @config_options.inspect
    record_hash = {}
    @config_options.each do |key|

      puts key.inspect
      value =  self.send(key)
      next if value.nil?  # Dont save empty keys
      record_hash[key.to_sym] = value
    end #each
    record_hash
  end


  private
  def open_configuration(name)
    return @db_conn.find_by_name(name)
  end



  # Dynamic methods below

  # Creates attribute accessor-ish methods that interact with the database in order to create an ORM model
  # Updates to the object attributes are propagated to the DB and vice versa, so explicit saves/loads dont need to be called
  # However this behaviour should probably be able to be toggled, as we might not always want instant propagation of attribute changes
  def _mk_updater_method(attr_name)
    self.class.send(:define_method,(attr_name + '=').to_sym) do |new_value|
      old_value = self.instance_variable_get(('@' + attr_name))
      create_or_update({attr_name.to_sym => old_value},{attr_name.to_sym => new_value})
      self.instance_variable_set(('@' + attr_name),new_value)
    end
  end

  # Similar to previous method, only creates readers instead of 'setters'
  def _mk_reader_method(attr_name)
    self.class.send(:define_method,(attr_name).to_sym) do
      self.instance_variable_get(('@' + attr_name))
    end
  end

  def _add_to_options(attr_name)
    @config_options.push(attr_name.to_sym) unless @config_options.include?(attr_name.to_sym)
  end




end
