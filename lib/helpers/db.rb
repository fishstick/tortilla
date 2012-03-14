require 'active_record'
require 'helpers/Dbsetup'

class VatfDB
  include Singleton
  include Setup

  attr_reader :db

  def initialize(db="/tmp/test.db")
    $db_log = Logger.new('/tmp/db.log')
    SQLite3::Database.new(db)
    ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => db)
  end

  def general_configuration
    GeneralConfiguration
  end
  def project_configuration
    ProjectConfiguration
  end
  def testcollection
    TestCollection
  end
  def testcase
    TestCase
  end
  def testrelation
    TestRelation
  end


  class ProjectConfiguration < ActiveRecord::Base
    def self.insert(opts={})
      self.create(opts)
    end

    def self.create_or_update(attrs_to_match,attrs_to_update={})
      if (incumbent = self.first(:conditions => attrs_to_match))

        $db_log.debug("Match found : #{incumbent}, updating existing entry")
        incumbent.update_attributes(attrs_to_update)
        incumbent
      else
        $db_log.debug("No previous match, creating new entry")
        insert(attrs_to_match.merge(attrs_to_update))
      end
    end
  end

  class GeneralConfiguration < ActiveRecord::Base
    has_many :options
    def self.server
      self.first.server
    end

    def self.devkey
      self.first.devkey

    end

    def self.insert(opts={})
      self.create(opts)
    end

    def self.create_or_update(attrs_to_match,attrs_to_update={})
      if (incumbent = self.first(:conditions => attrs_to_match))

        $db_log.debug("Match found : #{incumbent}, updating existing entry")
        incumbent.update_attributes(attrs_to_update)
        incumbent
      else
        $db_log.debug("No previous match, creating new entry")
        insert(attrs_to_match.merge(attrs_to_update))
      end
    end
  end

  class TestCollection < ActiveRecord::Base
    has_and_belongs_to_many :test_cases ,:join_table => "test_relations"

    def add_test(test)
      self.test_cases << test
    end

    def delete_test(test)
      self.test_cases.delete(test)
    end


    def self.create_or_update(attrs_to_match,attrs_to_update={})
      if (incumbent = self.first(:conditions => attrs_to_match))

        $db_log.debug("Match found : #{incumbent}, updating existing entry")
        incumbent.update_attributes(attrs_to_update)
        incumbent
      else
        $db_log.debug("No previous match, creating new entry")
        self.create(attrs_to_match.merge(attrs_to_update))
      end
    end
  end


  class TestCase < ActiveRecord::Base
    has_and_belongs_to_many :test_collections,:join_table => "test_relations"


    def self.create_or_update(attrs_to_match,attrs_to_update={})
      if (incumbent = self.first(:conditions => attrs_to_match))

        $db_log.debug("Match found : #{incumbent}, updating existing entry")
        incumbent.update_attributes(attrs_to_update)
        incumbent
      else
        $db_log.debug("No previous match, creating new entry")
        self.create(attrs_to_match.merge(attrs_to_update))
      end
    end
  end


end