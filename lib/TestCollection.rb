


# A Test collection is defined as the relationship between a test project and test plan, and the testcases matching those parameters

class TestCollection
  require 'ostruct'
  require 'find'


  include Exceptions

  attr_accessor :plan,:plan_id,:project,:project_id,:available_platforms,:prefix,:current_build,:open_builds,:prefix ,:active_platforms
  attr_reader :db_entry, :test_cases


  # config in this case is a Configuration object
  # testlink_obj is an  TestlinkWrapper.new(config.server,config.devkey)
  # @option opts :
  def initialize(testlink_obj,opts={})
    @log = Logger.new(Tortilla::DEV_LOG)
    raise ParameterError, "TestCollection needs to be initialized with a TestLink object"  unless testlink_obj.class == TestlinkWrapper
    @testlink = testlink_obj

    _set_instance_vars_from_opts(opts)
    self.available_platforms = []
    self.active_platforms = []
    @test_cases = []
  end

  # List summary of remote testcases matching current testrun attributes
  def list_remote
    requirement_hook{ @testlink.list_testcases(self) }
  end

  # Get full
  def fetch_remote
    requirement_hook { @testlink.fetch_testcases(self)  }
  end

  def fetch_and_add_testcases

    #puts 'TESPLATS!'
    #puts get_platforms

    @log.debug("Fetch and Add testcases!")
    i = 1


    fetch_remote.each do |test|
      # Test is a hash that should have at least 1 k/v pair
      # Keyed by the platform_id
      if test.length > 1
        test.each do |platform_id,testcase_info|
          add_test(testcase_info)
        end
      else
        raise RuntimeError,"I dont know what to do with myself: tests.length < 1"

      end # testlength  > 1

      yield i if block_given? # For interface actions
      i += 1
    end
    self
  end

  def add_test(test)
    if test.class == TestCase
      testcase = test
    elsif test.class == Hash
      testcase = TestCase.new(test)
    else
      @log.debug("Unrecognized test type (#{test.class}). Not adding to collection")
    end
    # We pull ALL testcases, and then evaluate if theyre going to be run wrt platforms

    @log.debug("testcase#{ testcase.external_id} has paltforms#{ testcase.platforms}")
    @log.debug("Adding test #{testcase.external_id} to collection for platform  #{testcase.platform_name}.")
    self.available_platforms <<  {:id => testcase.platform_id, :name => testcase.platform_name} unless self.available_platforms.include?({:id => testcase.platform_id, :name => testcase.platform_name})
    @test_cases.push(testcase)
  end

  def find_local_features
    # Set expected feature path
    if Config.active_config.featurepath
      feature_path =  Config.active_config.featurepath
    else
      feature_path = Config.active_config.basepath + '/features/'
    end

    # Find features
    i = 0
    found = 0
    self.test_cases.each do |test_case|
      Find.find(feature_path) do |file|
        if File.directory?(file)
          next
        else
          if File.basename(file) =~ Regexp.new((Config.active_config.prefix +  test_case.external_id))
            test_case.file = file
            found +=1
            break
          else
            next
          end
        end
      end
      i+= 1
    end
    yield found if block_given? # For interface actions

  end

  # Remove tests from the collection that have no matching local file
  # This is used prior to saving
  # Or maybe prior to running?
  # TODO
  def remove_unlinked_tests
    @test_cases.each do |testcase|
      remove_test(testcase)   if (testcase.file.nil? || testcase.file.empty?)
    end
  end


  # Remove an existing testcase from the test collection
  def remove_test(test_case)
    @log.debug("Removing testcase #{test_case.name} from collection")
    @test_cases.delete_at(@test_cases.index(test_case))
  end


  # Saves this testrun as a serialized YAML file
  def save!(full_file_path=nil)

    if (full_file_path.nil? || full_file_path.empty?)
      # Use defaults
      path = Tortilla::HOME_DIR
      base = ""
    else
      path =  File.dirname(full_file_path)
      base = File.basename(full_file_path)

    end
    # Create a yaml based on our self and each testcase object for easy re-load
    save_file_contents =  _create_yaml_from_objects

    # test if file exists and all that
    @log.debug("Saving collection to #{full_file_path}")
    write_file(full_file_path,save_file_contents)

  end


  # Changes self instance vars to the values of those found in a previously-saved testcolelction made by 'save!'
  def load!(full_file_path=nil)
    if (full_file_path.nil? || full_file_path.empty?)
      # Use defaults
      path = Tortilla::HOME_DIR
      base = ""
    else
      path =  File.dirname(full_file_path)
      base = File.basename(full_file_path)
    end
    save_file_contents = YAML.load(read_file(full_file_path)).marshal_dump
    @log.debug("Loading collection from #{full_file_path}")
    # The save file contents are now a proper hash, so set its contents to our own instance.
    _set_instance_vars_from_opts(save_file_contents)
  end



  def write_file(output_file_path,output_data)
    @log.debug("Writing to #{output_file_path} ")
    begin
      tf = File.new(output_file_path,'w+')
      tf.write(output_data)
      tf.close
    end
    @log.debug("File written at #{output_file_path}! ")
  end


  def read_file(input_file_path)
    tf = File.open(input_file_path)
    return tf.read
  end

  def current_build_name
    if self.current_build
      self.current_build[:name]
    else
      nil
    end
  end

  def get_platforms
    requirement_hook{ @testlink.get_platforms_for_testplan(self.plan_id) }
  end

  # Returns true if all required vars are set
  # During the process it also sets them, so things like current_build can be evaluated from outside
  # And helpfully also
  def prepared?
    begin
      requirement_hook { return true }
    rescue ArgumentError
      return false
    end

  end

  ########
  private



  # Creates a yaml from self instance vars
  # In order to facilitae creating a save file, we use openstruct to generate a proper save object
  # This is then serialized with YAML .
  def _create_yaml_from_objects

    @log.debug("Creating a Save File>")
    save = ::OpenStruct.new
    # We need plan, plan id, project, project id
    ['plan','plan_id','project','project_id','available_platforms'].each do |element|
      save.send("#{element}=", self.send(element))
    end
    # And the testcases
    @log.debug("adding testcases to save...")
    save.test_cases = []
    self.test_cases.each do |tc|
      save.test_cases << tc
    end
    @log.debug("Converting save to YAML...")
    save =  save.to_yaml
    @log.debug('Save conversion done <')
    return save
  end


  # For any remote actions to work, we require at least project and testplan
  # Therefore, we check this every single time before trying remote actions
  def requirement_hook(&block)
    if _basic_requirements_set?
      _set_remote_requirements
      yield block
    else
      raise ArgumentError, "Missing some required settings. View log for details."
    end
  end




  # The basic requirements for a TestCollection to function beyond initialisation are a testplan and testproject
  # if these aren't set, no TL actions can be performed
  def _basic_requirements_set?
    bool = true
    [:plan,:project].each do |instance_var|
      instance_var_name = ('@' + instance_var.to_s)
      if !self.instance_variable_defined?(instance_var_name)
        @log.debug("Missing required instance var: #{instance_var_name}")
        bool = false
        break
      end
    end
    bool
  end


  # For each K/V pair, sets an instance variable with name K to value V
  def  _set_instance_vars_from_opts(opts)
    opts.each do |name,value|
      self.instance_variable_set(('@' + name.to_s).to_sym,value)
    end
  end


  # Same as   _set_instance_vars_from_opts, except for a config instead of a hash
  # May be deprecated
  def _set_instance_vars_from_config(config)
    config.config_options.each do |config_option|
      # Only internalize relevant config options  µ
      case config_option
        when :plan,:project,:server,:devkey
          config_value = config.send(config_option)
          @log.debug("TestCollection internalizing config option: #{config_option} => #{config_value}")
          self.instance_variable_set(('@' + config_option.to_s).to_sym,config_value)
      end

    end
  end



  # Sets and validates remote requirements based on given basic requiremetns (specifically: self.project and self.plan)
  # based on the basic requirements (plan name and project name), we determine their IDs and any builds related to those projects
  # Because of the ORM model, we do this EVERY time, as the plan and/or project may have changed, and an unsynced ORM is a terrible thing.
  # Because of the ORM model, we do this EVERY time, as the plan and/or project may have changed, and an unsynced ORM is a terrible thing.
  def _set_remote_requirements
    @log.debug("Attempting to set remote requirements >")

    @log.debug("Finding Project ID")
    self.project_id = @testlink.project_id_from_name(self.project)
    @log.debug("Project ID: Set(#{self.project_id.inspect})")

    @log.debug("Finding plan ID")
    self.plan_id = @testlink.find_test_plans_for_project_id( self.project_id, self.plan)[:id]
    @log.debug("Plan ID: Set(#{self.plan_id.inspect}).")

    @log.debug("Finding Builds")
    self.open_builds = @testlink.get_open_buildnames_for_testplan(self.plan_id)
    @log.debug("Builds found (#{self.open_builds}).")
    _validate_open_builds


    @log.debug("Remote Requirements set!!")
  end

  # Make decisions based on how many open builds there are.
  # If 0 => we can't do anything wrt test collection
  # if = 1 => Good, just use that build
  # if > 1, grab the first build in the array (the newest-added), but store all found open builds in self.open_builds, so user can still set self.current_build
  def _validate_open_builds
    if self.open_builds.length == 0
      raise RemoteError,"No open builds found to collect tests from. Open at least one build for current test plan!"
    elsif self.open_builds.length == 1
      self.current_build = self.open_builds.first
      @log.debug("Perfect, only one build is open")
      # good
    elsif self.open_builds.length > 1
      # Pick newest, but warn
      # Should be toggle-able behaviour probably
      if self.current_build
        @log.warn("Multiple builds found, but already have a current_build set (#{self.current_build_name}) - not overwriting!")

      else
        @log.debug("Found multiple builds, current build not set: using most recent build in list.")
        self.current_build = self.open_builds.first
      end
    end
  end

end
