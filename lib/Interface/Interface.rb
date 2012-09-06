

# Non- menu related Interface methods
# coloured puts, message boxes, hjeaders, breadcrumbs, etc.
module Interface

class Display
  require 'highline/import'

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



  def msg_box(msg)
    puts cli_say(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::',:bold)
    puts
    puts msg
    puts
    puts cli_say(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::',:bold)
    puts
  end



  # Display the currently loaded:
  # * config
  # *project
  # * plan
  # * builds
  # TODO: Genericize/futureproof a bit?
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

  # TODO: Unused?
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

end # class



end


