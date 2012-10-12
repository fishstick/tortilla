module Interface
  # Highline Menus and user interface flow
  module Menus

    MM_ACTIONS =  ['Select a new Testcollection',
                   'Load a Saved Testcollection',
                   'Start a testrun',
                   'Report results',
                   'Configure Tortilla',
                   'Exit tortilla']


    TEST_OPTIONS = ['Save Test Collection',
                    'Change build',
                    'Back to main',
                    'Exit Tortilla'
    ]

    # Open a
    # ex: open_menu('start a testrun')
    # > looks for a method named start_a_testrun_menu
    def open_menu(menu_choice,opts={})
      # Menu choice is the entire menu choice string
      #menu_name = menu_choice.split.first.downcase + '_menu'
      menu_name =  menu_choice.gsub(' ','_').downcase + '_menu'
      # Menu exists
      if self.respond_to?(menu_name)
        System.clear_screen
        if opts[:display_name]
          display_name =  opts[:display_name]
        else
          display_name = menu_choice.split.first + ' Menu'
        end
        @cli.crumb_add(display_name)  # Add current menu location to breadcrumb
        if config.nil?
          config_name = config
        else
          config_name = config.name
        end
                                      # 'self' in this context refers to Harness, where this module is extended
        puts @cli.show_header({:config => config_name,:testplan => self.plan,:testproject => self.project,:build => self.current_build_name  })
        self.send(menu_name)
        @cli.crumb_del(display_name)
      else
        # an unknown  menu: probably a Dev error
        puts "Menu definition #{menu_name} doesnt exist"
        exit
      end
    end




    # Loop to find a file in a path matching to an given glob .Prompting a user for paths, until only one file is found or selected
    # handled cases:
    # * path is a filename => dont check extension (Config validation handles the rest)
    # * path contains no .conf files => re-ask
    # * path contains multiple conf files => let user choose
    # * path contains 1 conf file => use it
    # ex for config: _find_file('tortilla.conf','*.conf')
    def _find_file(filename,glob)
      found = []
      while found.to_a.length != 1 do # to_a because if a single result is returned, length returns amount of chars in str
        dir = @cli.ask("Enter path or filename for #{filename}")
        if File.directory?(dir)
          found = Dir.glob(dir + '/' + glob)
          # Found multiple, make user choose one
          if found.length > 1
            @cli.choose do |menu|
              menu.index = :number
              menu.layout = :list
              found.each do |config|
                menu.choice(config)   { |choice|
                  found = [choice]
                }
              end
              menu.prompt = ("Found multiple matching files in provided directory, please choose one" )
            end

          elsif found.length == 0
            puts "No matching files found in that directory..."

          elsif found.length == 1
            puts "okay, using #{found.first}"
            return found.first
          end
        elsif File.exists?(dir)
          # File exists, use
          found = dir
          return found
        else
          puts "Provided path is neither a file nor a directory... what are you doing?"
        end
      end
      return found.first
    end


    def configure_tortilla_menu
      found = Dir.glob(Dir.pwd + '/*.conf')
      if found.length > 1
        # multiple
        @cli.choose do |menu|
          menu.index = :number
          menu.layout = :list
          found.each do |config|
            menu.choice(config)   { |choice|
              load_config(choice)
            }
          end
          menu.prompt = ("Found multiple matching files in current directory, please choose one" )
        end

      elsif found.length == 1
        @cli.msg_box("No config loaded, but I found a config in your current directory! ")
        load = @cli.agree("Do you want to load the config #{found.first}? Y/N ")
        if load
          # load config
          load_config(found)
        else
          # find config loop
          load_config(_find_file('Tortilla.conf','*.conf'))
        end

      else # No config in PWD
           # Offer choice between generting an example and editing it
           # or loading an existing one
        @cli.msg_box('No config loaded, or found in current directory.')
        @cli.choose do |menu|
          menu.index = :number
          menu.layout = :list

          menu.choice("Generate Example Conf") do  |choice|

            _generate_config

          end
          menu.choice("Load Existing conf") do  |choice|
            load_config(_find_file('Tortilla.conf','*.conf'))
          end
          menu.prompt = ("You can either point to an existing config, or let Tortilla generate an example config." )
        end

      end   # if found length

      # Config should be loaded now
      puts 'Config loaded! Returning to Main menu'
    end


    def main_menu
      @cli.choose do |menu|
        menu.index = :number
        menu.layout = :list
        MM_ACTIONS.each do |action|
          menu.choice(action)   { |choice|
            open_menu(choice)
          }
        end
        menu.prompt = ("
      Please select an action.")
      end
    end

    def exit_tortilla_menu
      exit
      exit
    end


    # Wrapper menu around actions requried for creating a new testcollection
    def select_a_new_testcollection_menu
      # First we select projects


      open_menu('Projects')

      # Then our plans, based on project
      open_menu('Plans')

      # By now we should have all required arguments to do stuff in testlink
      # To verify this, (and also set them so we can check current_build before fetching tests)
      # We query Testcollection
      if @test_collection.prepared?
        # [{:name=>"MDP 2.3.4.1", :id=>778}, {:name=>"MDP 2.3.4.11", :id=>901}, {:name=>"first-automation", :id=>712}, {:name=>"mdp_2.3.3.5_dev_1.2.11_books_1.1.5", :id=>784}]
        # Let user pick build if there's more than 1 open build. TestCollection handles the evaluation of open_builds in other cases.
        open_menu('Builds') if @test_collection.open_builds.length > 1

        puts 'Fetching tests, this may take a while...'
        print "Tests found:  "
        fetch_tests do  |i|
          print i
          sleep 0.01
          i.to_s.length.times { print "\b"}
        end
        open_menu('Tests')
      end
      # And then save, or save + run now

    end



    # TODO: Show matching files in PWD?
    def load_a_saved_testcollection_menu

      file_path =   @cli.ask("Enter path/filename to load testcollection from ")do  |q|
        q.default = "./tests.torti"
      end


      @test_collection.load!(file_path)

      puts 'TestCollection loaded!'
      sleep 1

    end



    def start_a_testrun_menu
      # Start a loaded testcoll
      # Validate
      # => Test if @testcollection is loaded
      # => test if @testcollection.test_cases is not empty
      # ===> if they are,  load_a_saved_testcollection_menu

      if @test_collection.test_cases.empty?
        # 2 possible cases
        # => There is already a saved one we can use
        @cli.say("No loaded tests found!")
        if @cli.agree('Have you already selected/created a testcollection?')
          open_menu('Load a Saved Testcollection')
        else
          # => User hasnt picked a new one yet
          open_menu('Select a new Testcollection')
        end
      else
        # Not an empty collection, continue with run
        if @test_collection.available_platforms.length > 1
          # More than one platform is available, make user choose action for each
          @log.debug("More than one platform was available, letting user pick active platforms for testing")
          open_menu('platforms')
        end

        # At this point platforms are selected, so we should probably do our testrun now
        # We select only the active tests (as defined by active_platforms) from our testcollection
        do_testrun(@test_collection.select_active_tests) # a Harness function


      end

    end




    # For each AVAILABLE platform, choose the ACTIVE ones
    def platforms_menu
      @log.debug("Available platforms:  #{@test_collection.available_platforms.inspect}")

      @test_collection.available_platforms.each do |platform_hash|
        puts @cli.cli_say("There are multiple available platforms. Choose an appropriate action for each one")


        choose do |menu|
          menu.index        = :number
          menu.index_suffix = ") "
          menu.prompt = "Choose action for platform #{platform_hash[:name]}: "

          menu.choice "Skip platform" do
            puts @cli.cli_say("=> Skipping platform...")
            platform_client = ""
          end


          menu.choice "Run on localhost" do
            platform_client = 'local'
            puts @cli.cli_say("=> Set #{platform_hash[:name]} to run on host #{platform_client}")
            @log.debug("Added active platform:  #{platform_hash.inspect}")
            @test_collection.active_platforms.push(platform_hash)

          end

          menu.choice "Run on Remote host" do
            platform_client = ask("Enter Remote client IP or Host for platform #{platform_hash[:name]}")

            # validate?
            puts @cli.cli_say("=> Set #{platform_hash[:name]} to run on host #{platform_client}.")
            @log.debug("Added active platform:  #{platform_hash.inspect}")
            @test_collection.active_platforms.push(platform_hash)

          end


        end

      end   # Each available paltforms





    end


    # Change active build
    def builds_menu
      builds = open_builds

      @cli.choose do |menu|
        menu.index = :number
        menu.layout = :list
        menu.flow = :columns_down
        builds.each do |test_option|
          menu.choice(test_option[:name])   { |choice|
            puts @cli.cli_say("You chose build #{choice}.",:green)
            @test_collection.current_build = test_option
          }
        end
        menu.choice('Cancel') {|choice| exit}

        menu.prompt = ("
      Choose a build.
")
      end

    end


    #####################################""
    # TEST RELATED
    def tests_menu()
      #@test_collection.test_cases
      @num_tests =  @test_collection.test_cases.length

      @cli.msg_box("
    Found #{@num_tests} tests for current build #{@test_collection.current_build_name}, over #{@test_collection.available_platforms.length} platforms!

")
      @cli.choose do |menu|
        menu.index = :number
        menu.layout = :list
        menu.flow = :columns_down
        TEST_OPTIONS.each do |test_option|
          menu.choice(test_option)   { |choice|
            puts @cli.cli_say("You chose #{choice}.",:green)
            open_menu(choice)
          }
        end
        menu.prompt = ("
      How would you like to continue?")
      end


    end

    # TODO


    def save_test_collection_menu
      # Save TC

      # TODO:
      # Add suggestion/help/warning when num_local = 0
      # eg: check prefix, feature path
      # and add re-find option
      find_local_features  do |i|
        @num_local = i
        @cli.msg_box(" Found #{i} matching local files for #{@num_tests} remote tests!")
      end
      # Find local features doesnt guarantee all tests actually have local files, it only updates the testcases for thsoe that DO have any files
      # and Since we should only save those that have matching files
      # We remove the testcases which have no linked loca files
      @test_collection.remove_unlinked_tests


      file_path =   @cli.ask("Enter path/filename to save testcollection to ")do  |q|
        q.default = "./tests.torti"
      end
      @test_collection.save!(file_path)
      sleep 5
      puts 'Testcollection saved as q, returning to main menu...'

    end



    ##########
    def projects_menu
      projects = list_projects

      @cli.choose do |menu|
        menu.index = :number
        menu.layout = :list
        menu.flow = :columns_down
        projects.each do |project_hash|
          menu.choice(project_hash[:name])   { |choice|
            puts @cli.cli_say("You chose Test Project #{choice}.",:green)
            self.project = choice

          }
        end
        menu.prompt = ("
      Please select a Test project")
      end

    end



    def plans_menu
      plans = list_testplans
      @cli.choose do |menu|
        menu.index = :number
        menu.layout = :list
        menu.flow = :columns_down
        plans.each do |plan_hash|
          menu.choice(plan_hash[:name])   { |choice|
            puts @cli.cli_say("You chose Test Plan #{choice}.",:green)
            self.plan = choice
          }
        end
        menu.prompt = ("
      Please select a Test Plan")
      end

    end


    def _generate_config
      puts Tortilla::EXAMPLE_CONF
    end


  end # module menus

end   # class interface