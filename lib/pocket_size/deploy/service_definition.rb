# frozen_string_literal: true

module PocketSize
  module Deploy
    class ServiceDefinition < TaskDefinition
      # @!attribute load_balancers
      #   @return [Array<LoadBalancer>]
      attribute :load_balancers, default: -> { Array.new }

      # @!attribute capacity_provider_strategies
      #   @return [Array<CapacityProviderStrategy>]
      attribute :capacity_provider_strategies, default: -> { Array.new }

      # @!attribute deployment_configuration
      #   @return [DeploymentConfiguration]
      attribute :deployment_configuration, default: -> { DeploymentConfiguration.new }

      # @!attribute health_check_grace_period
      #   @return [Integer]
      attribute :health_check_grace_period, :integer, default: 300

      # @param json [Hash{String => Object}]
      # @return [PocketSize::Deploy::ServiceDefinition]
      def self.from_json(json)
        # @type [PocketSize::Deploy::ServiceDefinition]
        obj = super(json)

        # Capacity provider strategies
        if json['capacity_provider_strategies'].is_a?(Array)
          obj.capacity_provider_strategies = json['capacity_provider_strategies'].map do |item|
            CapacityProviderStrategy.new(item.transform_keys(&:to_sym))
          end
        end

        # Deployment configuration
        if json['deployment_configuration'].is_a?(Hash)
          obj.deployment_configuration = DeploymentConfiguration.new(
            json['deployment_configuration'].transform_keys(&:to_sym)
          )
        end

        # Load balancers
        if json['load_balancers'].is_a?(Array)
          obj.load_balancers = json['load_balancers'].map do |item|
            LoadBalancer.new(item.transform_keys(&:to_sym))
          end
        end

        obj
      end

      def cf_resource_id
        'SRV' + Base32.encode("#{name}").gsub('=', '')
      end

      def init_process_enabled?
        init_process_enabled == true
      end

      class LoadBalancer < Model
        # @!attribute port
        #   @return [Integer]
        attribute :port, :integer

        # @!attribute target_group
        #   @return [String, nil]
        attribute :target_group, :string

        # @!attribute target_group_arn
        #   @return [String]
        attribute :target_group_arn, :string
      end

      class CapacityProviderStrategy < Model
        # @!attribute name
        #   @return [String]
        attribute :name, :string

        # @!attribute base
        #   @return [Integer]
        attribute :base, :integer

        # @!attribute weight
        #   @return [Integer]
        attribute :weight, :integer, default: 1
      end

      class DeploymentConfiguration < Model
        # @!attribute minimum_percentage
        #   @return [Integer]
        attribute :minimum_percentage, :integer, default: 100

        # @!attribute maximum_percentage
        #   @return [Integer]
        attribute :maximum_percentage, :integer, default: 200
      end
    end
  end
end
