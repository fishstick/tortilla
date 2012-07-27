module Tortilla
  require 'rubygems'
  require 'sqlite3'
  require 'logger'
  require 'singleton'


  # Own classes
  DEV_LOG = "/tmp/dev.log"
  DB_LOG = "/tmp/db.log"

  require 'lib/helpers/testlink_wrapper'
  require 'lib/helpers/Exceptions'


  require 'lib/DataBase'
  require 'lib/Config'
  require 'lib/TestCase'
  require 'lib/TestCollection'
  require 'lib/Harness'


end

