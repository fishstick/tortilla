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
        #puts test_case.inspect
        test_case = test_case.first
        tc_arr.push(test_case)
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
      @log.debug("LIST TESTCASE - A testcase: #{test_case_hash.inspect}")
      all << {test_case_hash['external_id'] => test_case_hash['name'] }
    end
    all
  end


end

