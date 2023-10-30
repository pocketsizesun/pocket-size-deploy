# frozen_string_literal: true

module PocketSize
  module Deploy
    class ScheduledTaskDefinition < TaskDefinition
      # @!attribute schedule_expression
      #   @return [String]
      attribute :schedule_expression, :string

      # @!attribute enabled
      #   @return [Boolean]
      attribute :enabled, :boolean, default: true

      # @param json [Hash{String => Object}]
      # @return [PocketSize::Deploy::ScheduledTaskDefinition]
      def self.from_json(json)
        # @type [PocketSize::Deploy::ScheduledTaskDefinition]
        obj = super(json)

        unless json['schedule_expression'].nil?
          obj.schedule_expression = json['schedule_expression']
        end

        unless json['enabled'].nil?
          obj.enabled = json['enabled']
        end

        obj
      end

      def cf_resource_id
        'SCH' + Base32.encode("#{name}").gsub('=', '')
      end

      def enabled?
        enabled == true
      end
    end
  end
end
