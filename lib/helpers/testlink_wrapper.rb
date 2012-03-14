require 'singleton'
require 'test_linker'
class TestlinkWrapper
  include Singleton

  # TMP

  def initialize
    @conf = VatfDB.instance.general_configuration
    @tl = TestLinker.new(@conf.server,@conf.devkey)
  end

  def project_id_from_name(project_name)
    @tl.project_id(project_name)
  end

  def find_test_plans_for_project_id(project_id,plan_regex)
    @tl.find_test_plans(project_id, Regexp.new(plan_regex))
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
      if build_hash[:is_open] == "1" then
        open_builds <<  build_hash[:name]
      end
    end
    return open_builds
  end

  def find_open_testcases(project_name,plan_regex,build,opts={})
    @tl.find_open_cases_for_plan(project_name, Regexp.new(plan_regex),{:build => Regexp.new(build)})
  end


  #Aggregates


  # Get testcases with full body
  def fetch_testcases(test_collection)
    unless test_collection.open_builds.empty?
      find_open_testcases(test_collection.project,test_collection.plan,(test_collection.current_build || test_collection.open_builds.first))
    else
      find_open_testcases(test_collection.project,test_collection.plan,(test_collection.current_build || test_collection.open_builds.first))

    end
  end

  # Only retrieve a list... exid + name only?
  def list_testcases(test_collection)
    test_cases = find_open_testcases(test_collection.project,test_collection.plan,(test_collection.current_build || test_collection.open_builds.first))
    all = []
    test_cases.each do |test_case_hash|
      all << {test_case_hash['external_id'] => test_case_hash['name'] }
    end
    all
  end


end

