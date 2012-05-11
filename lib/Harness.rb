
class Harness
  attr_accessor :test_collection,:config

  def initialize(opts={})
    @test_collection = TestCollection.new(opts)
    @config = ConfigSet.new(opts)
  end


  def retrieve_remote_tests
    #@test_collection.list_remote
    #puts "A wizard asks you to continue Y/N"
    # wiz-ask "pick these?"
    @test_collection.fetch_remote
  end

  def collect_tests # piçker's 'collect test' equiv
    retrieve_remote_tests.each do |single_test_hash|
      testcase = TestCase.new(single_test_hash)
      testcase.find_local_feature
      @test_collection.add_test(testcase)   # Add each test to this collection
    end
    @test_collection.save!
  end




end
