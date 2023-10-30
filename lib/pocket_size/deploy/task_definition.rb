# frozen_string_literal: true

module PocketSize
  module Deploy
    class TaskDefinition < Model
      LAUNCH_TYPE_EC2          = 'EC2'
      LAUNCH_TYPE_FARGATE      = 'FARGATE'
      LAUNCH_TYPE_FARGATE_SPOT = 'FARGATE_SPOT'

      NETWORK_MODE_AWSVPC = 'awsvpc'
      NETWORK_MODE_BRIDGE = 'bridge'
      NETWORK_MODE_HOST   = 'host'

      # @!attribute name
      #   @return [String]
      attribute :name, :string

      # @!attribute count
      #   @return [Integer]
      attribute :count, :integer, default: 1

      # @!attribute task_execution_role_name
      #   @return [String]
      attribute :task_execution_role_name, :string

      # @!attribute task_role_name
      #   @return [String]
      attribute :task_role_name, :string

      # @!attribute network_mode
      #   @return [String]
      attribute :network_mode, :string, default: NETWORK_MODE_AWSVPC

      # @!attribute cpu
      #   @return [Integer, nil]
      attribute :cpu, :integer, default: nil

      # @!attribute memory
      #   @return [Integer, nil]
      attribute :memory, :integer, default: nil

      # @!attribute ephemeral_storage_size
      #   @return [Integer, nil]
      attribute :ephemeral_storage_size, :integer, default: nil

      # @!attribute image_url
      #   @return [String, nil]
      attribute :image_url, :string

      # @!attribute entrypoint
      #   @return [Array<String>, nil]
      attribute :entrypoint

      # @!attribute command
      #   @return [Array<String>, nil]
      attribute :command

      # @!attribute ports
      #   @return [Array<String>]
      attribute :ports, default: -> { Array.new }

      # @!attribute port_mappings
      #   @return [Array<PortMapping>]
      attribute :port_mappings, default: -> { Array.new }

      # @!attribute launch_type
      #   @return [String, nil]
      attribute :launch_type, :string, default: nil

      # @!attribute init_process_enabled
      #   @return [Boolean]
      attribute :init_process_enabled, :boolean, default: false

      # @!attribute environment
      #   @return [Hash{String => String}]
      attribute :environment, default: -> { Hash.new }

      # @!attribute swap_size
      #   @return [Integer, nil]
      attribute :swap_size, :integer, default: nil

      # @!attribute shared_memory_size
      #   @return [Integer, nil]
      attribute :shared_memory_size, :integer, default: nil

      # @!attribute swappiness
      #   @return [Integer]
      attribute :swappiness, :integer, default: 60

      # @!attribute kernel_capabilities
      #   @return [Hash{String => Boolean}]
      attribute :kernel_capabilities, default: -> { Hash.new }

      # @!attribute system_controls
      #   @return [Hash{String => String}]
      attribute :system_controls, default: -> { Hash.new }

      # @param json [Hash{String => Object}]
      # @return [PocketSize::Deploy::TaskDefinition]
      def self.from_json(json)
        new(
          {
            name: json['name'],
            count: json['count'],
            task_execution_role_name: json['task_execution_role_name'],
            task_role_name: json['task_role_name'],
            network_mode: json['network_mode'],
            cpu: json['cpu'],
            memory: json['memory'],
            ephemeral_storage_size: json['ephemeral_storage_size'],
            image_url: json['image_url'],
            entrypoint: json['entrypoint'],
            command: json['command'],
            ports: json['ports'],
            port_mappings: json['port_mappings']&.map do |item|
              PortMapping.from_json(item)
            end,
            launch_type: json['launch_type'],
            init_process_enabled: json['init_process_enabled'],
            environment: json['environment'],
            swap_size: json['swap_size'],
            shared_memory_size: json['shared_memory_size'],
            swappiness: json['swappiness'],
            kernel_capabilities: json['kernel_capabilities'],
            system_controls: json['system_controls']
          }.compact
        )
      end

      def cf_resource_id
        raise NotImplementedError
      end

      def cf_task_definition_resource_id
        "#{cf_resource_id}TD"
      end

      def ports=(arg)
        return unless arg.is_a?(Array)

        self.port_mappings = arg.collect do |item|
          port_spec, protocol = item.split('/', 2)
          app_protocol, container_port, host_port = port_spec.split(':', 3)

          PortMapping.new(
            {
              app_protocol: app_protocol,
              container_port: container_port,
              host_port: host_port,
              protocol: protocol
            }.compact
          )
        end
      end

      def init_process_enabled?
        init_process_enabled == true
      end

      class PortMapping < Model
        PORT_PROTOCOLS = %w[grpc http http2].freeze

        # @!attribute name
        #   @return [String, nil]
        attribute :name, :string

        # @!attribute app_protocol
        #   @return [String]
        attribute :app_protocol, :string

        # @!attribute container_port
        #   @return [Integer]
        attribute :container_port, :integer

        # @!attribute host_port
        #   @return [Integer, nil]
        attribute :host_port, :integer

        # @!attribute protocol
        #   @return [String]
        attribute :protocol, :string, default: 'tcp'

        # @param json [Hash{String => Object}]
        # @return [PocketSize::Deploy::TaskDefinition::PortMapping]
        def self.from_json(json)
          new(
            {
              name: json['name'],
              app_protocol: json['app_protocol'],
              container_port: json['container_port'],
              host_port: json['host_port'],
              protocol: json['protocol']
            }.compact
          )
        end
      end
    end
  end
end
