module BlockchainService
  module ConnectionConfigurable
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :configuration

      def configure
        self.configuration ||= Configuration.new
        yield(configuration)
      end
    end

    class Configuration
      attr_accessor :connection

      def initialize
        @connection = {}
      end
    end
  end
end
