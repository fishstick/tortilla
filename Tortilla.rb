
require 'rubygems'
require 'logger'
require 'singleton'
require 'sys/uname'
require 'progress_bar'

require_relative 'lib/helpers/Constants'
require_relative 'lib/helpers/testlink_wrapper'
require_relative 'lib/helpers/Exceptions'
require_relative 'lib/Interface/Interface'
require_relative 'lib/Interface/menus'
require_relative 'lib/Config'
require_relative 'lib/Harness'
require_relative 'lib/TestCase'
require_relative 'lib/TestCollection'
include Constants



#TORTILLA USAGE
# foo = Tortilla.new('tortilla.conf')
# Set requirements
# foo.project='MYDIGIPASS.COM'
# foo.plan='mdp-2.x.x.x'

# List or fetch testcases
# foo.list_tests
# => {267=>"Create a new user account (HW digipass)"}
# OR foo.fetch_tests - this adds them to the collection

# We can now see which platforms are available, since fetch gets ALL testcases.
# foo.test_collection.available_platforms
#=> [{:id=>"368", :name=>"IE_9"}, {:id=>"376", :name=>"Ipad_Safari"}, {:id=>"587", :name=>"Chrome_23"},
#{:id=>"651", :name=>"Firefox_18"}, {:id=>"663", :name=>"Chrome_24"}, {:id=>"664", :name=>"ipod"},
# {:id=>"665", :name=>"android"}, {:id=>"666", :name=>"Firefox_19"}, {:id=>"671", :name=>"Chrome_25"}]

# Since no platforms have been picked, active_tests will be empty:
# foo.test_collection.active_tests?
# => []

# # Set an active platform from one of the available ones (in Array format)
# foo.test_collection.active_platforms <<  foo.test_collection.available_platforms.first

# Now active_tests will contain the tets for that platform:
# foo.test_collection.active_tests?.length
# => 82

# The full test_collection still contains ALL tests. If you save now, those will also be saved
# To cull them to only the active tests:
# foo.test_collection.remove_inactive_tests



class Tortilla

  attr_accessor :test_collection,:config,:cli,:testlink
  include Exceptions
  include Interface::Menus



  def initialize(config_name=nil)
    @log = Logger.new(Tortilla::DEV_LOG)
    unless config_name.nil?
      load_config(config_name)
      _set_requirements
    end
  end

  # Load and parse a config
  # Automatically uses values in config to create Testlink objects and initialize other components
  def load_config(config_name)
    @config = TortillaConfig::open_and_parse(config_name)
    _set_requirements
  end

  # Lists projects visible in testlink for this devkey
  def list_projects
    _requirement_hook { @testlink.find_projects(/\w/) }
  end

  # Lists testplans visible in testlink for this devkey
  def list_testplans(full=false)
    _requirement_hook do
      project_id = @testlink.project_id_from_name(self.project)
      res = @testlink.find_test_plans_for_project_id(project_id,/\\w/)
      return res
    end
  end

  # Lists tests in external_id => name Hash format. Does NOT add them to the test_collection
  def list_tests
    _requirement_hook { @test_collection.list_remote }
  end

  # Fetches and Converts all visible tests in testlink in to TestCase objects and adds them to the test_collection
  def fetch_tests
    _requirement_hook do
      @test_collection.fetch_and_add_testcases   do   |num|
        yield num if block_given?
      end
      #System.clear_screen
    end
    return @test_collection.test_cases
  end

  #
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
        open_menu('Main',{:config => self.config})
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




  # Starts a testrun of a given array of TestCase objects
  # TODO
  def do_testrun()
    raise RuntimeError,"Not yet Implemented!"
  end



  private
  # Pivotal method - loads the config, then uses the config values to prepare critical objects of underlying structures
  def _set_requirements(opts={})
    @log.debug("Setting requirements")
    @testlink = TestlinkWrapper.new(@config.testlink_server,@config.dev_key)
    @test_collection = TestCollection.new(@testlink,opts)
  end


  # Test whether sub-requirements are set
  # Methods that require either config, testlink or testlink collection are wrapped in this hook
  # So that a proper warning is given, rather than an ugly nil-error
  def _requirement_hook(&block)
    if (@testlink && @test_collection)
      yield block
    else
      _set_requirements
      msg =  "No config was loaded - can't perform actions that rely on it! Use load_config and/or create_config"
      puts msg
      @log.warn(msg)
    end
  end






























end



