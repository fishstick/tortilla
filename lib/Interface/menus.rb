#module Menus
#
#  MM_ACTIONS =  ['Select a new testrun',
#                 'Run a previously-selected testrun',
#                 'Report results of a previous testrun',
#                 'Configure Tortilla or change configurations.',
#                 'Exit tortilla']
#
#
#  TEST_OPTIONS = ['View Summary',
#                  'Change build',
#                  'Save Test Collection',
#                  'Exit Tortilla'
#  ]
#
#  # Open a
#  def open_menu(menu_choice,opts={})
#    # Menu choice is the entire menu choice string
#    # We use the first word in the menu_choice to determine the next menu item
#    menu_name = menu_choice.split.first.downcase + '_menu'
#
#    # Menu exists
#    if self.respond_to?(menu_name)
#      System.clear_screen
#      pretty_name = menu_choice.split.first + ' Menu'
#      @cli.crumb_add(pretty_name)  # Add current menu location to breadcrumb
#      puts @cli.show_header({:config => config.name,:testplan => self.plan,:testproject => self.project,:build => @test_collection.current_build_name  })
#
#
#      self.send(menu_name)
#      @cli.crumb_del(pretty_name)
#
#
#    else
#      # an unknown  menu: probably a Dev error
#      puts 'doesnt exist'
#    end
#  end
#
#
#
#
#  def main_menu
#    @cli.choose do |menu|
#      menu.index = :number
#      menu.layout = :list
#      MM_ACTIONS.each do |action|
#        menu.choice(action)   { |choice|
#          open_menu(choice)
#        }
#      end
#      menu.prompt = ("
#      Please select an action.")
#    end
#
#  end
#
#
#
#
#  def exit_menu
#    exit
#  end
#
#
#  # Select test project and test plan
#  # Then create a Testcollection based on info
#  def select_menu
#    # menu for selecting testplans and such
#    # First we select projects
#    open_menu('Projects')
#
#    # Then our plans, based on project
#    open_menu('Plans')
#
#    # By now we should have all required arguments to do stuff in testlink
#    # To verify this, (and also set them so we can check current_build before fetching tests)
#    # We query Testcollection
#    if @test_collection.prepared?
#      open_menu('Tests')
#    end
#
#
#    # And then save, or save + run now
#
#  end
#
#  # Change active build
#  def change_menu
#    builds = open_builds
#
#    @cli.choose do |menu|
#      menu.index = :number
#      menu.layout = :list
#      menu.flow = :columns_down
#      builds.each do |test_option|
#        menu.choice(test_option[:name])   { |choice|
#          puts @cli.cli_say("You chose build #{choice}.",:green)
#          @test_collection.current_build = test_option
#          open_menu('Tests')
#        }
#      end
#      menu.choice('Cancel') {|choice| exit}
#
#      menu.prompt = ("
#      Choose a build.
#")
#    end
#
#  end
#
#
#  def tests_menu
#    tests = get_tests
#    num = tests.length
#
#    @cli.msg_box("
#    Found #{num} tests for current build #{@test_collection.current_build[:name]}!
#
#")
#
#    @cli.choose do |menu|
#      menu.index = :number
#      menu.layout = :list
#      menu.flow = :columns_down
#      TEST_OPTIONS.each do |test_option|
#        menu.choice(test_option)   { |choice|
#          puts @cli.cli_say("You chose #{choice}.",:green)
#          open_menu(choice)
#        }
#      end
#      menu.prompt = ("
#      How would you like to continue?")
#    end
#
#    sleep 10
#
#  end
#
#
#
#  def projects_menu
#    projects = list_projects
#
#    @cli.choose do |menu|
#      menu.index = :number
#      menu.layout = :list
#      menu.flow = :columns_down
#      projects.each do |project_hash|
#        menu.choice(project_hash[:name])   { |choice|
#          puts @cli.cli_say("You chose Test Project #{choice}.",:green)
#          self.project = choice
#
#        }
#      end
#      menu.prompt = ("
#      Please select a Test project")
#    end
#
#  end
#
#
#
#  def plans_menu
#    plans = list_testplans
#    @cli.choose do |menu|
#      menu.index = :number
#      menu.layout = :list
#      menu.flow = :columns_down
#      plans.each do |plan_hash|
#        menu.choice(plan_hash[:name])   { |choice|
#          puts @cli.cli_say("You chose Test Plan #{choice}.",:green)
#          self.plan = choice
#        }
#      end
#      menu.prompt = ("
#      Please select a Test Plan")
#    end
#
#  end
#
#
#
#
#
#end