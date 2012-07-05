
class Harness
  attr_accessor :test_collection,:config

  def initialize(config_name,opts={})
    $log = Logger.new('/tmp/dev.log')
    @config = TortillaConfig.new(:name => config_name)
    @testlink = TestlinkWrapper.new(@config.server,@config.devkey)

    @test_collection = TestCollection.new(@testlink,opts)
  end




end
