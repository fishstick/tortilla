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
    @db_conn = VatfDB.instance
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
    if (existing_testcollection = VatfDB.instance.testcollection.last(:conditions => {:project_id => self.project_id,:plan_id => self.plan_id}) )
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



# Old 'fetch'
#def collect_testlink_cases(options={})
#    project_name     = @testproject || options[:testproject]
#    plan_regex       = @testplan    || options[:testplan]
#    prefix           = @prefix      || options[:prefix]       || @platform
#    testhash         = {}
#    testhash[:tests] = {}
#    URGENCIES.each do |urg|
#      testhash[:tests][urg] = {}
#    end
#    # build general info hash
#    testhash[:tproject_id] = project_id = @tl.project_id(project_name)
#    test_plans = @tl.find_test_plans(project_id, Regexp.new(plan_regex))
#    # TEMP support for new/OLD TL (See https://github.com/turboladen/test_linker/issues/12 )
#    if test_plans.is_a?(Array) then  # This is irrelevant now I think, since thi sis provided by Picker
#      raise VatfCore::ParameterError,'Found multiple matching testplans. Specify a more narrow regex for test plan!' if test_plans.length >= 2
#      test_plans = test_plans.first
#    end
#    # This is irrelevant now I think, since this is provided by Picker
#    raise VatfCore::ParameterError,'Found no matching testplans. Specify a more narrow regex for test plan!' if test_plans.nil?
#
#    testhash[:tplan] = test_plans[:name]
#    testhash[:tplan_id] = test_plans[:id]
#    testhash[:tproject] = project_name
#    testhash[:platform] = @platform || "n/a"
#    testhash[:testplan_platforms] = {}
#    puts "doin call"
#    begin
#      @tl.getTestPlanPlatforms(testhash[:tplan_id]).each do |test_platform|
#        testhash[:testplan_platforms][test_platform[:name]] = {:id => test_platform[:id] }
#      end
#
#    rescue TestLinker::Error
#      # No platforms
#    end
#
#    puts("Found #{testhash[:testplan_platforms].length} platforms. Enter remote host for each, or Enter to skip/use localhost.")
#    testhash[:testplan_platforms].keys.each do |platform_name|
#      platform_client = ask("Remote client for platform #{platform_name} (Enter for Local)")
#      if platform_client.empty?
#        puts("Localhost chosen.")
#        platform_client = 'local'
#      else
#        puts("Host #{platform_client} chosen.")
#      end
#      testhash[:testplan_platforms][platform_name][:client] = platform_client
#    end
#    builds = @tl.builds_for_test_plan(test_plans[:id])
#    # If we find more than one build: Check how many are open
#    #   - If more than 1 OPEN build is found, hard exit: User should specify buildname or fix testlink config.
#    #   - If more than one build is found, but only one is open -> use that one
#    #   - If only one build is found -> nothing special -> use that one
#    open_builds = []
#    builds.each do |build_hash|
#      if build_hash[:is_open] == 1 then
#        open_builds <<  build_hash[:name]
#      end
#    end
#    if open_builds.length == 0 then
#      raise  VatfCore::ParameterError,'No open builds available for testplan: no available testcases!'
#    elsif open_builds.length == 1 then
#      @build = open_builds.first
#    elsif open_builds.length > 1 then
#      @build = enum2menu(open_builds,{:prompt => "Please pick a build"})
#    end
#    testhash[:build] = @build # for FTTH structure
#    cases_to_run = []
#    testcases = @tl.find_open_cases_for_plan(project_name, Regexp.new(plan_regex),{:build => Regexp.new(testhash[:build])})
#    num_tests = 0
#    raise VatfCore::ParameterError,'No testcases assigned to given build or testplan!' if testcases.nil? || testcases.empty?
#    loop do
#      testcases.each do |tc_info|
#
#        test_platform = tc_info[:platform_name] #browser
#
#        exid=  (tc_info['external_id'] || tc_info[:external_id]).to_s
#        tcid = (tc_info['tc_id'] || tc_info[:tc_id])
#        ex_type =  (tc_info['execution_type']) ||  (tc_info[:execution_type]).to_s
#        urgency =  (tc_info['urgency']) ||  (tc_info[:urgency])
#
#
#
#        new_testcase =  {:exid => prefix.downcase + exid,
#                         :tcid => tcid,
#                         :urgency => urgency.to_s,
#                         :assigned_platforms => [test_platform]
#        }
#                                                #Check if this is a tc with the same exid, fi so => platforms
#        cases_to_run.select do |testcase|
#          if testcase[:exid] == new_testcase[:exid]
#            puts 'match, deleting'
#            new_testcase[:assigned_platforms] << testcase[:assigned_platforms].first
#            cases_to_run.delete_at(cases_to_run.index(testcase))
#          end
#        end
#       puts "TC: #{new_testcase.inspect}, EX TYPE: #{ex_type}"
#        if options[:greedy] then  # pull all cases, or just the automated ones?
#          cases_to_run << new_testcase
#        else
#          cases_to_run << new_testcase if ex_type == '2'
#        end
#      end
#
#              puts "NEW C2R"
#        puts cases_to_run.inspect
#        puts cases_to_run.length
#
#      if cases_to_run.length == 0 && testcases.length >= 1 then
#        if agree("Pull ALL cases instead? Answering 'No' will exit VATF")
#          #  re-iterate with greed
#          cases_to_run = []
#          options[:greedy] = true
#        else
#          raise VatfCore::ParameterError,"Found remote testcases, but none set to automated, and you chose not to pull Manual testcases"
#        end
#      else
#        break  # break loop if results ok (more than 1 case to run)
#      end
#    end # loop
#
#    # Now everything has been retrieved from testlink, compare with local features
#    cases_to_run.each do |tc|
#      filename = `find #{@featurepath} -name #{tc[:exid]}*`
#      $log.debug("Looking for #{cases_to_run.length} tests in #{@featurepath}")
#      if filename.empty? then
#        $log.debug("No local feature file found for TC #{tc[:exid]}")
#      else
#        testhash[:tests][tc[:urgency]][tc[:exid]] = {:file => filename,
#                                                     :id => tc[:tcid],
#                                                     :urgency => tc[:urgency],
#                                                     :platforms => tc[:assigned_platforms] }
#        num_tests += tc[:assigned_platforms].length
#      end
#    end
#    if testhash[:tests].empty? then
#      if cases_to_run.length >= 1 then
#        put_nok("Found one ore more testcases, but no local feature files!")
#        put_nok "Please make sure prefix/platform and featurepath are set correctly."
#        exit
#      end
#      err_handler('No local testfiles found! Confirm prefix/platform and feature path.')
#    end
#    testhash[:number_of_tests] = num_tests
#    testhash
#  end