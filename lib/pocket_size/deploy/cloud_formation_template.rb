# frozen_string_literal: true

module PocketSize
  module Deploy
    class CloudFormationTemplate
      ERB_TEMPLATE = ERB.new(File.read(File.realpath("#{File.dirname(__FILE__)}/../../../templates/cloudformation.yml.erb")))

      def self.render(configuration)
        new(configuration).render
      end

      # @param configuration [PocketSize::Deploy::Configuration]
      def initialize(configuration)
        @configuration = configuration
        @service_definitions = configuration.services
        @scheduled_task_definitions = configuration.scheduled_tasks
      end

      def render
        ERB_TEMPLATE.result(binding)
      end
    end
  end
end
