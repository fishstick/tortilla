require 'singleton'
require 'test_linker'
class TestlinkWrapper

  def initialize(server,devkey)
    @log = Logger.new(Tortilla::DEV_LOG)
    @log.debug("TL CONNECTING to #{server} ,#{devkey}")
    @tl = TestLinker.new(server,devkey)
  end

  def find_projects(project_name,opts={:full => false})
    project_name = Regexp.new(project_name) unless project_name.class == Regexp
    all_projects = @tl.find_projects(project_name)
    res = []
    if opts[:full] == true
      # show all projects
      res = all_projects
    else
      # show only active projects
      all_projects.each do |project_hash|
        if project_hash.has_key?(:active) && (project_hash[:active] == 1 || project_hash[:active] == "1")
          res << project_hash
        else
          @log.debug("Project #{project_hash[:name]} is not an active project, skipping. Use :full => true if desired")
        end
      end
    end #unless
    return res
  end

  def project_id_from_name(project_name)
    return @tl.project_id(project_name)
  end

  def find_test_plans_for_project_id(project_id,plan_regex)
    plan_regex = Regexp.new(plan_regex) unless plan_regex.class == Regexp
    res = @tl.find_test_plans(project_id, Regexp.new(plan_regex))
    res
  end


  def get_platforms_for_testplan(testplan_id)
    @tl.getTestPlanPlatforms(testplan_id)
  end

  def get_builds_for_testplan(testplan_id)
    @tl.builds_for_test_plan(testplan_id)
  end

  def get_open_buildnames_for_testplan(testplan_id)
    builds = @tl.builds_for_test_plan(testplan_id)
    open_builds = []
    builds.each do |build_hash|
      if (build_hash[:is_open] == "1"|| build_hash[:is_open] == 1) then
        open_builds <<  {:name => build_hash[:name], :id => build_hash[:id] }
      end
    end
    return open_builds
  end

  def find_open_testcases(plan_id,build_id,opts={})
    @log.debug("Find open testscases for plan ID #{plan_id.inspect} and build ID #{build_id.inspect}")
    test_cases = @tl.test_cases_for_test_plan(plan_id,{ "buildid" =>build_id })
    tc_arr = []
    unless (test_cases.nil? || test_cases.empty?) then
      #  We return all testcases and let the other functiosn and/or TestCollection handle the sorting
      test_cases.each_value do |test_case|
        #puts 'IN TL WRAPPER'
        #puts test_case.inspect
        #sleep 5
        # We can't just take 'first'
        # The hash is keyed by each platform
        # eg


        # In case of testsuite: An Array
        #[{"urgency"=>"2", "assigned_build_id"=>"", "linked_ts"=>"2012-01-19 08:10:16", "tcversion_number"=>"", "tc_id"=>"10991", "status"=>"", "execution_ts"=>"", "execution_run_type"=>"", "executed"=>"", "version"=>"3", "platform_id"=>"0", "z"=>"100", "exec_on_tplan"=>"", "tsuite_name"=>"CDRom bootability test", "exec_id"=>"", "linked_by"=>"22", "feature_id"=>"64644", "tester_id"=>"", "importance"=>"2", "type"=>"", "exec_on_build"=>"", "execution_order"=>"1000", "tcversion_id"=>"41835", "name"=>"TC1", "assigner_id"=>"", "user_id"=>"", "summary"=>"", "testsuite_id"=>"10990", "execution_notes"=>"", "active"=>"1", "priority"=>"4", "external_id"=>"2", "platform_name"=>"", "exec_status"=>"n", "execution_type"=>"1"}]


        # TODO: In case of NO  platforms??



        # In case of 1 platform:  A Hash
        # {39=>{:exec_on_build=>"", :type=>"", :summary=>"", :tcversion_id=>41835, :execution_order=>1000, :linked_by=>22, :priority=>4, :active=>1, :assigned_build_id=>"", :execution_notes=>"", :linked_ts=>"2012-01-19 08:10:16", :status=>"", :testsuite_id=>10990, :execution_ts=>"", :tester_id=>"", :execution_run_type=>"", :platform_name=>"TPR-HW1-X-SWA", :exec_id=>"", :importance=>2, :tcversion_number=>"", :z=>100, :platform_id=>39, :execution_type=>1, :urgency=>2, :exec_status=>"n", :tc_id=>10991, :name=>"TC1", :assigner_id=>"", :version=>3, :tsuite_name=>"CDRom bootability test", :feature_id=>64644, :executed=>"", :external_id=>2, :exec_on_tplan=>"", :user_id=>""}}


        # In case of multiple platforms: :  A Hash
        #notesnamechromeid359
        #notesnamefirefoxid358
        #IN TL WRAPPER
        #{
        #358=>{:type=>"", :execution_type=>1, :tester_id=>"", :summary=>"<p>Filesets can be deleted. Those  Filesets can be assigned to zero, one of more ASP&nbsp;Applications for the given  ASP.</p>\n<p><strong><span style=\"color: rgb(255, 0, 0);\">Note: it is unclear if only the Vasco Admin Operator should be able to do this, or also the ASP&nbsp;Operator?</span></strong></p>", :linked_by=>5, :active=>1, :tc_id=>11914, :priority=>4, :exec_status=>"n", :status=>"", :exec_on_build=>"", :importance=>2, :user_id=>"", :tsuite_name=>"File Sets", :execution_order=>1000, :linked_ts=>"2012-01-17 14:52:06", :platform_name=>"firefox", :tcversion_id=>11915, :assigner_id=>"", :z=>100, :platform_id=>358, :exec_on_tplan=>"", :testsuite_id=>11788, :tcversion_number=>"", :urgency=>2, :name=>"Delete Application Fileset", :execution_run_type=>"", :executed=>"", :external_id=>325, :assigned_build_id=>"", :feature_id=>63397, :execution_notes=>"", :version=>1, :execution_ts=>"", :exec_id=>""},
        # 359=>{:type=>"", :execution_type=>1, :tester_id=>"", :summary=>"<p>Filesets can be deleted. Those  Filesets can be assigned to zero, one of more ASP&nbsp;Applications for the given  ASP.</p>\n<p><strong><span style=\"color: rgb(255, 0, 0);\">Note: it is unclear if only the Vasco Admin Operator should be able to do this, or also the ASP&nbsp;Operator?</span></strong></p>", :linked_by=>5, :active=>1, :tc_id=>11914, :priority=>4, :exec_status=>"n", :status=>"", :exec_on_build=>"", :importance=>2, :user_id=>"", :tsuite_name=>"File Sets", :execution_order=>1000, :linked_ts=>"2011-12-14 12:34:17", :platform_name=>"chrome", :tcversion_id=>11915, :assigner_id=>"", :z=>100, :platform_id=>359, :exec_on_tplan=>"", :testsuite_id=>11788, :tcversion_number=>"", :urgency=>2, :name=>"Delete Application Fileset", :execution_run_type=>"", :executed=>"", :external_id=>325, :assigned_build_id=>"", :feature_id=>60926, :execution_notes=>"", :version=>1, :execution_ts=>"", :exec_id=>""}
        #}





        #test_case = test_case.first
        tc_arr.push(test_case)   unless test_case.class == Array    # dont add suites
      end
    end
    tc_arr
  end



  def get_platforms_for_testplan(plan_id)
    @tl.getTestPlanPlatforms(plan_id)

  end



#Aggregates


# Get testcases with full body
  def fetch_testcases(test_collection)
    unless test_collection.open_builds.empty?
      find_open_testcases(test_collection.plan_id,(test_collection.current_build[:id] || test_collection.open_builds.first[:id]))
    else
      raise Exceptions::RemoteError, "Need at least one open build"
      find_open_testcases(test_collection.plan_id,(test_collection.current_build[:id] || test_collection.open_builds.first[:id]))
    end
  end

# Only retrieve a list... exid + name only?
  def list_testcases(test_collection)
    test_cases = find_open_testcases(test_collection.plan_id,(test_collection.current_build[:id] || test_collection.open_builds.first[:id]))
    all = []
    test_cases.each do |test_case_hash|
      tc = test_case_hash.values.first # Strip off first key
      @log.debug("LIST TESTCASE - A testcase: #{test_case_hash.inspect}")
      all << { tc[:external_id] =>  tc[:name] }   # TODO: Use symbols
    end
    all
  end


end

