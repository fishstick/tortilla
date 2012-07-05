
class TestCollection
  include Exceptions

  attr_accessor :plan,:plan_id,:project,:project_id,:platforms,:prefix,:current_build,:open_builds
  attr_reader :db_entry


  # config in this case is a Configuration object
  # testlink_obj is an  TestlinkWrapper.new(config.server,config.devkey)
  def initialize(testlink_obj,opts={})
    $log = Logger.new('/tmp/dev.log')
    raise ParameterError, "TestCollection needs to be initialized with a TortillaConfig object"  unless testlink_obj.class == TestlinkWrapper
    @testlink = testlink_obj
    @db_conn = TortillaDB.instance
    _set_instance_vars_from_opts(opts)
    @test_cases = []
    @db_entry = save_or_find_existing # See if there's a db-saved copy of this testcollection already!
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
    $log.debug("Fetch and Add testcases!")
    fetch_remote.each do |test|
      add_test(test)
    end
    self
  end

  def add_test(test)
    if test.class == TestCase
      testcase = test
    elsif test.class == Hash
      testcase = TestCase.new(test)
    else
      $log.debug("Unrecognized test type (#{test.class}). Not adding to collection")
    end

    testcase_db_entry =  testcase.save_to_db
    self.db_entry.add_test(testcase_db_entry)
    @test_cases.push(testcase)
  end


  # Saves this testrun
  def save!
    save_or_find_existing

    unless (self.testcases.nil? || self.testcases.empty?)

    end
  end

  def load!(opts={})
    requirement_hook { load_from_db(opts.merge!(:plan_id => self.plan_id, :project_id =>  self.project_id)) }
  end

  def testcases
    if @db_entry
      @db_entry.test_cases.all
    else
      @test_cases
    end
  end





  ########
  private
  # For any remote actions to work, we require at least project and testplan
  def requirement_hook(&block)
    if _basic_requirements_set?
      _set_remote_requirements
      yield block
    else
      raise ArgumentError, "Missing some required settings. View log for details."
    end
  end
  def load_from_db(opts={})
    @db_entry = @db_conn.testcollection.find(:last, :conditions => {:project_id => self.project_id,:plan_id => self.plan_id}.merge(opts))
  end

  def find_existing
    requirement_hook do

      if self.project_id && self.plan_id
        if (existing_testcollection = TortillaDB.instance.testcollection.last(:conditions => {:project_id => self.project_id,:plan_id => self.plan_id}) )
          return  existing_testcollection

        end
      else
        puts 'Either plan_id or projectid is nil, not polling DB'
      end

    end



  end

  # Save current, or find an existing saved Testrun
  def save_or_find_existing
    record_hash = _create_collection_record
    if (existing_testcollection = TortillaDB.instance.testcollection.last(:conditions => {:project_id => self.project_id,:plan_id => self.plan_id}) )
      puts 'found one'
      puts existing_testcollection.inspect
      return existing_testcollection
    else
      puts 'new'
      return @db_conn.testcollection.create_or_update(record_hash)
    end

  end

  def _basic_requirements_set?
    bool = true
    [:plan,:project].each do |instance_var|
      instance_var_name = ('@' + instance_var.to_s)
      if !self.instance_variable_defined?(instance_var_name)
        $log.debug("Missing required instance var: #{instance_var_name}")
        bool = false
        break
      end
    end
    bool
  end

  def _create_collection_record
    puts 'Creating collection record'
    record_hash = {}
    self.instance_variables.each do |var|
      case var
        when '@collection','$log','@db_conn','@testlink','@db_entry'
          # dont save
        else
          key = var.split('@').last
          value =  self.instance_variable_get(var)
          record_hash[key.to_sym] = value
      end
    end #each
    record_hash
  end


  def  _set_instance_vars_from_opts(opts)
    opts.each do |name,value|
      self.instance_variable_set(('@' + name.to_s).to_sym,value)
    end
  end


  def _set_instance_vars_from_config(config)
    config.config_options.each do |config_option|
      # Only internalize relevant config options  µ
      case config_option
        when :plan,:project,:server,:devkey
          config_value = config.send(config_option)
          $log.debug("TestCollection internalizing config option: #{config_option} => #{config_value}")
          self.instance_variable_set(('@' + config_option.to_s).to_sym,config_value)
      end

    end
  end


  # Sets and validates remote requirements based on given basic requiremetns (specifically: self.project and self.plan)
  #
  def _set_remote_requirements
    $log.debug("Attempting to set remote requirements >")

    $log.debug("Finding Project ID")
    self.project_id = @testlink.project_id_from_name(self.project)
    $log.debug("Project ID: Set(#{self.project_id.inspect})")

    $log.debug("Finding plan ID")
    self.plan_id = @testlink.find_test_plans_for_project_id( self.project_id, self.plan)[:id]
    $log.debug("Plan ID: Set(#{self.plan_id.inspect}).")

    $log.debug("Finding Builds")
    self.open_builds = @testlink.get_open_buildnames_for_testplan(self.plan_id)
    $log.debug("Builds found (#{self.open_builds}).")
    _validate_open_builds


    $log.debug("Remote Requirements set!!")
  end

  def _validate_open_builds
    if self.open_builds.length == 0
      raise RemoteError,"No open builds found to collect tests from. Open at least one build for current test plan!"
    elsif self.open_builds.length == 1
      self.current_build = self.open_builds.first
      # good
    elsif self.open_builds.length > 1
      # Pick newest, but warn
      # Should be toggle-able behaviour probably
      self.current_build = self.open_builds.first
      $log.warn("Multiple builds found, auto-selecting newest build (#{self.current_build}). Set desired build manually, if needed.")
    end
  end

end
