# A configset consists of:
# * A name, which is unique
# * An id linking to the GeneralConfiguration it uses
# * an id linking to the nameconfiguration it uses
# * An array of which options are exposed/public


class TortillaConfig
  attr_reader :name,:smtp_host

  def initialize(opts={})
    @db_conn = TortillaDB.instance.configuration
    self.load_config(opts[:name])  if (opts && opts.has_key?(:name) )
  end



  # Overwrites existing configs wit that name
  def create_or_update(opts,update_opts={})
    if self.name
     @db_conn.create_or_update({:name => self.name}.merge(opts),update_opts)
	puts "Created config #{self.name}"
    end
  end



  def load_config(name)
    if (record = open_name_configuration(name))
      record.attribute_names.each do |attr_name|
        self.instance_variable_set(('@' + attr_name),record.read_attribute(attr_name))
        _mk_updater_method(attr_name)  # make attr_accessor-like method that auto-updates the DB values, too...
      end
    else
      puts "Something wrong, attempted to load a config but no records were found for that name"
    end
  end

  def open_name_configuration(name)
    @db_conn.name_configuration.find_by_name(name)
  end


  def list_configs
    @db_conn.all
  end

  def update(search_opts,new_opts)
    @db_conn.name_configuration.create_or_update({:name => self.name}.merge(search_opts),new_opts)
  end




  private
  # Creates attribute accessor-ish methods
  # example
  # attr_name = 'smtp_host'
  # => def smtp_host=(new_value)
  def _mk_updater_method(attr_name)
    self.class.send(:define_method,(attr_name + '=').to_sym) do |new_value|
      old_value = self.instance_variable_get(('@' + attr_name))
      update({attr_name.to_sym => old_value},{attr_name.to_sym => new_value})
      self.instance_variable_set(('@' + attr_name),new_value)
    end
  end
  
  
  
  
end
