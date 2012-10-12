module SystemCommands
  OPTIONMAP =  {:require => ' -r ',:outputdir => ' -o ',:format => ' --format '}
  @@bin = "/usr/bin/env cucumber "


#outputdir
# format (html/human)
#  opts.on('-b', '--browser BROWSER', "Browser to run tests in") do |browser|
#    ENV['BROWSER_TYPE'] = browser
#  end
#  opts.on('-c', '--client CLIENT', "Browser to run tests in") do |client|
#    ENV['BROWSER_CLIENT'] = client
#  end
#
#



  # ex: add_option :require => '/support/env.Rb'
  def set_options_from_hash(option_hash)
    option_hash.each_pair do |option_name,option_value|
      @@bin << OPTIONMAP[option_name] + option_value
    end
  end



end
