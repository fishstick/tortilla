class Interface
  require 'highline/import'


  # Constants containing some static menu items
  # The first word in each choice is used to determine which is the next wizard/menu to open


  def initialize
    # Create required colorschemes
    ft = HighLine::ColorScheme.new do |cs|
      cs[:headline]        = [ :bold, :yellow, :on_black ]
      cs[:horizontal_line] = [ :bold, :white ]
      cs[:warn]           = [:bold, :red]
      cs[:ok]             =[:bold,:green]
    end
    HighLine.color_scheme = ft
    @crumb = []
  end


  def cli_say(string,colorscheme=nil)
    colorscheme = colorscheme.to_sym unless (colorscheme.nil? || colorscheme.class == Symbol)
    return ::HighLine.new.color(string,colorscheme)
  end

  ## wraps text with a newline after +col+
  #def wrap_text(txt, col = 50)
  #  txt.gsub(/(.{1,#{col}})( +|$)\n?|(.{#{col}})/,
  #           "\\1\\3\n ")
  #end


  def msg_box(msg)
    puts cli_say(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::',:bold)
    puts msg
    puts cli_say(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::',:bold)
    puts
  end




  def show_status(status_hash)
    ok_butt = cli_say('*',:ok)
    bad_butt = cli_say('*',:warn)
    conf_str = ""
    plan_str = ""
    proj_str = ""
    build_str = ""

    # :config => {:status => ok,:value =>'Myconfig' }
    status_hash.each do |component_name,component_value|
      case component_value
        when nil
          status = "[" + bad_butt + "] "
        else
          status = "[" + ok_butt + "] "
      end

      case component_name
        when :config
          conf_str = status +  "Config: " + (component_value || 'N/A')
        when :testplan
          plan_str = status +  "Test Plan: " + (component_value || 'N/A')
        when :testproject
          proj_str = status + "Test Project: " + (component_value || 'N/A')
        when :build
          build_str = status + 'Build: '  +  (component_value || 'N/A')
      end
    end

    str=<<-EOF
#{conf_str}
#{proj_str}
#{plan_str}
#{build_str}
    EOF
  end

  def show_config(config)
    cli_say(config.name,:green)
  end

  # Breadcrumb related methods
  def show_crumb
    crumb_l = @crumb.length
    i=1
    str= "::"
    @crumb.each do |crumb_el|
      if i == crumb_l
        str << cli_say(crumb_el,:bold)
      else
        str << cli_say(crumb_el,:bold) + ':>'
      end
      i+=1
    end
    str
  end

  def crumb_add(new)
    @crumb << new
  end
  def crumb_del(new)
    @crumb.pop
    @crumb
  end

  def show_header(status_hash)
    heredoc=<<-EOF
 _____          _   _ _ _
|_   _|        | | (_) | |
  | | ___  _ __| |_ _| | | __ _
  | |/ _ \\| '__| __| | | |/ _` |
  | | (_) | |  | |_| | | | (_| |
  \\_/\\___/|_|   \\__|_|_|_|\\__,_|

[#{show_crumb}]
#{show_status(status_hash)}
    EOF
  end






  #########################

  ###########""













  module Menus

    MM_ACTIONS =  ['Select a new Testcollection',
                   'Run a Saved Testcollection',
                   'Report results',
                   'Configure Tortilla',
                   'Exit tortilla']


    TEST_OPTIONS = ['View Summary',
                    'Change build',
                    'Save Test Collection',
                    'Exit Tortilla'
    ]

    # Open a
    def open_menu(menu_choice,opts={})
      # Menu choice is the entire menu choice string
      # We use the first word in the menu_choice to determine the next menu item
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
        puts @cli.show_header({:config => config.name,:testplan => self.plan,:testproject => self.project,:build => @test_collection.current_build_name  })


        self.send(menu_name)
        @cli.crumb_del(display_name)


      else
        # an unknown  menu: probably a Dev error
        puts "Menu definition #{menu_name} doesnt exist"
        exit
      end
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




    def exit_menu
      exit
    end


    # Select test project and test plan
    # Then create a Testcollection based on info
    def select_a_new_testcollection_menu
      # menu for selecting testplans and such
      # First we select projects
      open_menu('Projects')

      # Then our plans, based on project
      open_menu('Plans')

      # By now we should have all required arguments to do stuff in testlink
      # To verify this, (and also set them so we can check current_build before fetching tests)
      # We query Testcollection
      if @test_collection.prepared?
        open_menu('Tests')
      end


      # And then save, or save + run now

    end

    # Change active build
    def change_build_menu
      builds = open_builds

      @cli.choose do |menu|
        menu.index = :number
        menu.layout = :list
        menu.flow = :columns_down
        builds.each do |test_option|
          menu.choice(test_option[:name])   { |choice|
            puts @cli.cli_say("You chose build #{choice}.",:green)
            @test_collection.current_build = test_option

            open_menu('Tests')
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
    def tests_menu
      tests = list_tests
      @num_tests = tests.length

      @cli.msg_box("
    Found #{@num_tests} tests for current build #{@test_collection.current_build_name}!

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

      sleep 10

    end

    # TODO
    def view_summary_menu
      puts @test_collection.test_cases.inspect



    end

    def save_test_collection_menu
      # Save TC
      @test_collection.save!
      get_tests_and_save

    end



    ##########""
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





  end




end # module






