
class Harness
  attr_accessor :test_collection,:config

  def initialize(config_name,opts={})
    $log = Logger.new('/tmp/dev.log')
    @config = TortillaConfig.new(:name => config_name)
    @testlink = TestlinkWrapper.new(@config.server,@config.devkey)

    @test_collection = TestCollection.new(@testlink,opts)
  end

 def list_projects
   res = @testlink.find_projects(/\w/)
   return res
end

  def list_testplans(full=false)
    project_id = @testlink.project_id_from_name(@test_collection.project)
    res = @testlink.find_test_plans_for_project_id(project_id,/\w/)
    return res
  end


end
