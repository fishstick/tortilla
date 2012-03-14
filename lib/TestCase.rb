#=> {:assigner_id=>"", :status=>"", :user_id=>"", :type=>"", :assigned_build_id=>"", :external_id=>325, :execution_type=>1, :execution_run_type=>"", :execution_notes=>"", :importance=>2,
#:tester_id=>"", :platform_name=>"chrome", :execution_ts=>"", :platform_id=>359, :active=>1, :tcversion_number=>"", :feature_id=>60926, :executed=>"", :tcversion_id=>11915, :testsuite_id=>11788, :linked_by=>5,
#:summary=>"<p>Filesets can be deleted. Those  Filesets can be assigned to zero, one of more ASP&nbsp;Applications for the given  ASP.</p>\n<p><strong><span style=\"color: rgb(255, 0, 0);\">Note: it is unclear if only the Vasco Admin Operator should be able to do this, or also the ASP&nbsp;Operator?</span></strong></p>",
#:z=>100, :linked_ts=>"2011-12-14 12:34:17", :exec_on_tplan=>"", :name=>"Delete Application Fileset", :urgency=>2, :exec_status=>"n", :execution_order=>1000, :version=>1, :tc_id=>11914, :tsuite_name=>"File Sets", :priority=>4, :exec_id=>""}

class TestCase
  attr_accessor :urgency,:file,:external_id,:internal_id,:platforms,:tl_props ,:name

  # Create a new TestCase object
  # If a testhash is provided, testcase object is immediately completed, otherwise properties can be set manually.
  def initialize(test_hash={})
    @urgency,@external_id,@tc_id,@execution_type,@name,@platform_id = nil
    @file = ""
    @tl_props = {}
    unless test_hash.empty?
      create_from_hash(test_hash)
    end
    self
  end


  def create_from_hash(testcase_hash)
    @tl_props = testcase_hash
    set_properties
  end


  def save_to_db(opts={})
    # We only save some testcase properties, not all of them
    test_record = _testcase_to_record.merge(opts)
    TortillaDB.instance.testcase.create_or_update(test_record)
  end

  def find_local_feature
    feature_path = TortillaDB.instance.project_configuration.base_path + '/features/'
    self.file = `find #{feature_path} -name #{self.external_id}*`
     # Is this implied? Eitehr let harnass do manual save, or do it within here... Safest would be doing it here as
    # the save function already checks for duplicates
     save_to_db
  end


##############
  private
  def set_properties
    set_run_status
    remove_wordy_properties
    set_tl_properties
  end


  def set_run_status
    case @tl_props[:run_status]
      when /y/
        @run = true
      when /n/
        @run = false
    end
    @tl_props.delete(:run_status)
  end

  def set_tl_properties
    @tl_props.each do |property,value|
      if (self.instance_variable_defined?(('@' + property.to_s))  && self.instance_variable_get(('@' + property.to_s)) == nil)     # is it an internal property we map 1:1  and don't have yet
        self.instance_variable_set(('@' + property.to_s),value )
        @tl_props.delete(property)
      end
    end
  end

  def remove_wordy_properties
    @tl_props.delete(:summary)
  end


  # TestCase object => DB record
  def _testcase_to_record
    record_hash = {}
    self.instance_variables.each do |var|
      case var
        when '@tl_props','@execution_type','@tc_id'
          # dont save
        else
          key = var.split('@').last
          value =  self.instance_variable_get(var)
          record_hash[key.to_sym] = value
      end
    end #each
    record_hash
  end



end
