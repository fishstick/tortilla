module Tortilla
  require 'rubygems'
  require 'sqlite3'
  require 'logger'
  require 'singleton'
  require 'sys/uname'
  require 'progress_bar'

  require 'lib/helpers/Constants'
  include Constants

  # Own classes

  require 'lib/helpers/testlink_wrapper'
  require 'lib/helpers/Exceptions'
  require 'lib/Interface/Interface'
  require 'lib/Interface/menus'
  require 'lib/DataBase'
  require 'lib/Config'
  require 'lib/TestCase'
  require 'lib/TestCollection'
  require 'lib/Harness'


  require 'lib/System'

  require 'highline/import'



     Gem.post_install do
       #stuff
     end





end

