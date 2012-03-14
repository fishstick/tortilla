class HarnessConfig
  attr_reader :project,:smtp_host

  def initialize(opts={})
    @db_conn = TortillaDB.instance
    self.load_config(opts[:project])  if (opts && opts.has_key?(:project) )
  end


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

  def load_config(project)
    if (record = open_project_configuration(project))
      record.attribute_names.each do |attr_name|
        self.instance_variable_set(('@' + attr_name),record.read_attribute(attr_name))
        _mk_updater_method(attr_name)  # make attr_accessor-like method that auto-updates the DB values, too...
      end
    else
      puts "Something wrong, attempted to load a config but no records were found for that project"
    end
  end

  def open_project_configuration(project)
    @db_conn.project_configuration.find_by_project(project)
  end


  def update(search_opts,new_opts)
    @db_conn.project_configuration.create_or_update({:project => self.project}.merge(search_opts),new_opts)
  end


  def create_or_update(opts,update_opts={})
    if self.project
      @db_conn.create_or_update({:project => self.project}.merge(opts),update_opts)
    end
  end

end