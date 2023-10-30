# frozen_string_literal: true

module PocketSize
  module Deploy
    class CloudFormationTemplate
      ERB_TEMPLATE = ERB.new(File.read(File.realpath("#{File.dirname(__FILE__)}/../../../templates/cloudformation.yml.erb")))

      def self.render(configuration, service_definitions)
        new(configuration, service_definitions).render
      end

      def initialize(configuration, service_definitions)
        @configuration = configuration
        @service_definitions = service_definitions
      end

      def render
        ERB_TEMPLATE.result(binding)
      end
    end
  end
end
