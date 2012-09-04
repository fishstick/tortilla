
# Harness is the top-most layer of Tortilla, enveloping all other Data structures such as TestCase, Config and Testcollection
# It provides public methods that use the lowerlying datastructures in order to provide a single point of reference

# TODO: Figure out a way to determine default Config name



class Harness
  attr_accessor :test_collection,:config,:cli,:testlink

  include Exceptions

  # A new Harness object

  def initialize(config_name=nil)
    @log = Logger.new(Tortilla::DEV_LOG)
    unless config_name.nil?
      load_config(config_name)
      set_requirements

    end
    @cli = Interface.new
    self.extend(Interface::Menus)  # extend  with all the Menus for selecting, so they don't pollute the class here
  end


  # Pivotal method - loads the config, then uses the config values to prepare critical objects of underlying structures
  def set_requirements(opts={})
    @log.debug("Setting requirements")
    @testlink = TestlinkWrapper.new(@config.testlink_server,@config.dev_key)
    @test_collection = TestCollection.new(@testlink,opts)
  end

  def load_config(config_name)
   @config = Config::open_and_parse(config_name)
   set_requirements
  end


  def list_projects
    _requirement_hook { @testlink.find_projects(/\w/) }
  end

  def list_testplans(full=false)
    _requirement_hook do
      project_id = @testlink.project_id_from_name(self.project)
      res = @testlink.find_test_plans_for_project_id(project_id,/\\w/)
      return res
    end
  end

  def list_tests
    _requirement_hook { @test_collection.list_remote }
  end

  def fetch_tests
    _requirement_hook do
      @test_collection.fetch_and_add_testcases   do   |num|
        yield num if block_given?
      end
      System.clear_screen
    end
    return @test_collection.test_cases
  end

  def find_local_features
    @test_collection.find_local_features do |find_result|
      yield find_result if block_given?
    end
  end

  def open_builds
    @test_collection.open_builds
  end



  # main routine
  def main
    loop do
      if self.config.nil?
        open_menu('Configure Tortilla')
      else
        open_menu('Main')
      end

    end

  end




  # attr Helpers
  def project
    if self.test_collection.nil?
      nil
    else

      self.test_collection.project
    end
  end
  def project=(new_project)
    self.test_collection.project=new_project
  end

  def plan
    if self.test_collection.nil?
      nil
    else
      self.test_collection.plan
    end
  end
  def plan=(new_plan)
    self.test_collection.plan=new_plan
  end

  def current_build_name
    if self.test_collection.nil?
      nil
    else
      self.test_collection.current_build_name
    end
  end




  private
  # Test whether sub-requirements are set
  # Methods that require either config, testlink or testlink collection are wrapped in this hook
  # So that a proper warning is given, rather than an ugly nil-error
  def _requirement_hook(&block)
    if (@testlink && @test_collection)
      yield block
    else
      set_requirements
      msg =  "No config was loaded - can't perform actions that rely on it! Use load_config and/or create_config"
      puts msg
      @log.warn(msg)
    end
  end









end
