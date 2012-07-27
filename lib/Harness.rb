
# Harness is the top-most layer of Tortilla, enveloping all other Data structures such as TestCase, Config and Testcollection
# It provides public methods that use the lowerlying datastructures in order to provide a single point of reference
class Harness
  attr_accessor :test_collection,:config


  # A new Harness object

  def initialize(config_name = nil)
    @log = Logger.new(Tortilla::DEV_LOG)
     if config_name
       load_config(config_name)
     else
       @config = TortillaConfig.new
     end

  end


  # Pivotal method - loads the config, then uses the config values to prepare critical objects of underlying structures
  def load_config(config_name,opts={})
    @log.debug("Loading config #{config_name}")
    @config = TortillaConfig.new(:name => config_name)
    @testlink = TestlinkWrapper.new(@config.server,@config.devkey)
    @test_collection = TestCollection.new(@testlink,opts)
  end


  def list_projects
    _requirement_hook do
      res = @testlink.find_projects(/\w/)
      return res
    end
  end

  def list_testplans(full=false)
    _requirement_hook do
      project_id = @testlink.project_id_from_name(@test_collection.project)
      res = @testlink.find_test_plans_for_project_id(project_id,/\w/)
      return res
    end
  end







  # attr Helpers
  def project
    self.test_collection.project
  end
  def project=(new_project)
    self.test_collection.project=new_project
  end

  def plan
    self.test_collection.plan
  end
  def plan=(new_plan)
    self.test_collection.plan=new_plan
  end

  private

  # Test whether sub-requirements are set
  # Methods that require either config, testlink or testlink collection are wrapped in this hook
  # So that a proper warning is given, rather than an ugly nil-error
  def _requirement_hook(&block)
    if (@config && @testlink && @test_collection)
      yield block
    else
      msg =  "No config was loaded - can't perform actions that rely on it! Use load_config and/or create_config"
      puts msg
      @log.warn(msg)
    end
  end


end
