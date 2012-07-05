module Exceptions

  class TortillaError < StandardError
    def initialize(message)
      if $log
        $log.error(self.class.to_s + " : " + message)
      end
      super
    end
  end

  class ConfigError < TortillaError
  end
  class ParameterError < TortillaError
  end
  class RemoteError < TortillaError
  end


end