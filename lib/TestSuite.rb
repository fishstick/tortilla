#testcase1 = TestCase.new
#testcase1.external_id = "123"
#testcase2 = TestCase.new
#testcase2.external_id = "654"
#testcollection = TestCollection.new
#
#

class TestCollection
  attr_accessor :plan,:plan_id,:project,:project_id,:platforms,:prefix,:current_build,:open_builds
  attr_reader :db_entry

  #@plan
  # @plan_id
  # @project
  # @platforms
  # @prefix
  # @build
  def initialize(opts={})
    @log = Logger.new('/tmp/dev.log')
    @testlink = TestlinkWrapper.instance
    @db_conn = TortillaDB.instance
    _set_instance_vars_from_opts(opts) unless opts.empty?
    _set_remote_requirements
    @db_entry = save_or_find_existing

  end


  def list_remote
    # testlink-interaction => fetch testcases matching TestCollection instance vars
    if _basic_requirements_set?      # need at least project and plan
      _set_remote_requirements
      @testlink.list_testcases(self)
    else
      raise ArgumentError, "Missing some required settings. View log for details."
    end
  end


  def fetch_remote
    if _basic_requirements_set?      # need at least project and plan
      _set_remote_requirements
      @testlink.fetch_testcases(self)
    else
      raise ArgumentError, "Missing some required settings. View log for details."
    end
  end

  def add_test(test)
    if test.class == TestCase
      testcase = test.save_to_db
    elsif test.class == Hash
      testcase = TestCase.new(test).save_to_db
    else
      @log.debug("Unrecognized test type (#{test.class}). Not adding to collection")
    end
    self.db_entry.add_test(testcase)
  end


  def save!
    save_to_db
  end

  def load!(opts={})
    load_from_db(opts)
  end

  def testcases
    @db_entry.test_cases.all
  end




  ########
  private


  def load_from_db(opts={})
    @db_entry = @db_conn.testcollection.find(:last, :conditions => {:project_id => self.project_id,:plan_id => self.plan_id}.merge(opts))
  end

  def save_or_find_existing
    record_hash = _create_collection_record
    if (existing_testcollection = TortillaDB.instance.testcollection.last(:conditions => {:project_id => self.project_id,:plan_id => self.plan_id}) )
      return existing_testcollection
    else
      return @db_conn.testcollection.create_or_update(record_hash)
    end
  end

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

  def _create_collection_record
    record_hash = {}
    self.instance_variables.each do |var|
      case var
        when '@collection','@log','@db_conn','@testlink','@open_builds'
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

  def _set_remote_requirements
    self.project_id = @testlink.project_id_from_name(self.project)
    self.plan_id = @testlink.find_test_plans_for_project_id( self.project_id, self.plan).first[:id]
    self.open_builds = @testlink.get_open_buildnames_for_testplan(self.plan_id)
  end

end
