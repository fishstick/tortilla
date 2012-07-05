class TortillaConfig

  attr_reader :config_options
  def initialize(opts={})
    @db_conn = TortillaDB.instance.configuration
    # If name given, open an existing config
    @config_options = []
    self.load(opts[:name])  if opts.has_key?(:name)
  end




  # Overwrites existing configs wit that name
  def create_or_update(opts,update_opts={})
    if self.name
      @db_conn.create_or_update({:name => self.name}.merge(opts),update_opts)
      puts "Created config #{self.name}"
    end
  end



  def load(name)
    if (record = open_configuration(name))
      record.attribute_names.each do |attr_name|
        self.instance_variable_set(('@' + attr_name),record.read_attribute(attr_name))
        _mk_updater_method(attr_name)  # make attr_accessor-like method that auto-updates the DB values, too...
        _mk_reader_method(attr_name)  # make attr_reader-like method that auto-updates the DB values, too...
        _add_to_options(attr_name) # Add to the list of config directives so other methods can easily distinguish between 'normal' instance vars and ORM vars
      end
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

  def save(search_opts,new_opts)
    @db_conn.create_or_update({:name => self.name}.merge(search_opts),new_opts)
  end

  def delete(name = self.name)
    if name.nil? || name.empty?
      puts "No config loaded and no name given"
    else
      @db_conn.delete!(name)
    end


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
      update({attr_name.to_sym => old_value},{attr_name.to_sym => new_value})
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
