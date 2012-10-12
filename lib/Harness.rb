
# Harness is the top-most layer of Tortilla, enveloping all other Data structures such as TestCase, Config and Testcollection
# It provides public methods that use the lowerlying datastructures in order to provide a single point of reference


class Harness
  attr_accessor :test_collection,:config,:cli,:testlink
  include Exceptions
  include Interface::Menus


  # A new Harness object

  def initialize(config_name=nil)
    @log = Logger.new(Tortilla::DEV_LOG)
    unless config_name.nil?
      load_config(config_name)
      set_requirements
    end
    @cli = Interface::Display.new

    # TODO: Menus should be in interface, but it uses a lot of vars that are part of Harness...
    # Such as as testplanetc,.. We need to find a way to propagate the current Harness status to @cli, constantly
    #self.extend(Interface::Menus)
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
  # TODO:
  # - Plugin system => for example, inject vmware_prep methods somehow
  # - Dont fix self on cuke, make binary/method independant of cuke
  def do_testrun(test_array)

    test_array.each do |test|
      puts "RUNNING TEST #{test.external_id}"
      puts 'file'
      puts test.file
      System.cuke(test.file)

    end
    exit
    #$log.info("Found #{testinfo[:number_of_tests].to_s} tests to run")
    #URGENCIES.each do |urgency|
    #  testinfo[:tests][urgency].each_value do |item|
    #    puts File.basename(item[:file])
    #  end
    #end

    #put_ok("Continue with these tests?")
    #unless agree("Y/N") then
    #  put_nok("Exiting at user request.")
    #  exit
    #end
    #if @configfile['reset'] && @configfile['vm_master_configuration'] then
    #  raise ArgumentError,"vm_machine was not specified in config file!" unless @configfile['vm_machine']
    #  put_ok("Preparing clone of master vmware image")
    #  ENV['VATF_LOGDIR'] = @outputdir
    #  prep_vmware_image(true)
    #end
    #puts ""
    #put_ok("TESTING IN PROGRESS")
    #@outputdir += testinfo[:build].downcase + "_" +  Time.now.strftime("%d%m_%H%M") + '/'
    #copy_pickle_file
    #write_lastrun_file
    #load_plugins(:global)
    #pbar = ProgressBar.new( testinfo[:number_of_tests],:counter,:bar,:elapsed )
    #URGENCIES.each do |urgency|
    #  testinfo[:tests][urgency].each do |exid,tc|
    #
    #    testinfo[:testplan_platforms].keys.each do |plat|
    #      $log.debug("Running testcase #{exid} for platform #{plat}")
    #      update_dir(exid,plat)
    #      load_plugins(:test)
    #      ENV['RESULTDIR'] = @resultdir
    #      pbar.increment!
    #      browser=plat.gsub(/^(.*)[_-](.*)$/,'\1').downcase
    #      system("#{@cukebin} -A -C #{@config_location} -b #{browser} -c #{testinfo[:testplan_platforms][plat][:client]} -l #{@resultdir} -o #{@resultfile} -h #{@testhost} \'#{tc[:file].chomp}\'")
    #      parse_results_from_html # parse results and write into a txt as well
    #      revert_vmware_image if @vm_current_config
    #    end
    #
    #
    #  end # each  test
    #end #each urgency
    #put_ok("TESTS COMPLETED!")
    #put_ok("Run 'canner' to review and report results.")
    #
    #rotate_vatflog
    #notify_by_mail({:to => @configfile['smtp_recipient'], :host => @configfile['smtp_host'], :type => :testrun_complete}) if @mail



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
