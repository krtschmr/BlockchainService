# module BlockchainService
#   module ConnectionConfigurable
#     class << self
#       attr_accessor :configuration
#     end

#     def self.configure
#       self.configuration ||= Configuration.new
#       yield(configuration)
#     end

#     class Configuration
#       attr_accessor :connection

#       def initialize
#         @connection = {}
#       end
#     end
#   end
# end