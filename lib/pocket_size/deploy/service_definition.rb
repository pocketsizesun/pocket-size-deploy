# frozen_string_literal: true

module PocketSize
  module Deploy
    class ServiceDefinition < Model
      # @!attribute name
      #   @return [String]
      attribute :name, :string

      # @!attribute task_execution_role_name
      #   @return [String, nil]
      attribute :task_execution_role_name, :string

      # @!attribute task_role_name
      #   @return [String, nil]
      attribute :task_role_name, :string

      # @!attribute count
      #   @return [Integer]
      attribute :count, :integer, default: 1

      # @!attribute cpu
      #   @return [Integer]
      attribute :cpu, :integer, default: 512

      # @!attribute memory
      #   @return [Integer]
      attribute :memory, :integer, default: 512

      # @!attribute ephemeral_storage_size
      #   @return [Integer]
      attribute :ephemeral_storage_size, :integer

      # @!attribute cpu_arch
      #   @return [String]
      attribute :cpu_arch, :string

      # @!attribute os_family
      #   @return [String]
      attribute :os_family, :string

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

      # @!attribute alb_target_group_arn
      #   @return [String]
      attribute :alb_target_group_arn, :string

      # @!attribute load_balancers
      #   @return [Array<LoadBalancer>]
      attribute :load_balancers, default: -> { Array.new }

      def cf_resource_id
        Base32.encode("#{name}").gsub('=', '')
      end

      def cf_task_definition_resource_id
        "#{cf_resource_id}TD"
      end

      def cf_service_resource_id
        "#{cf_resource_id}SRV"
      end

      def ports=(arg)
        return unless arg.is_a?(Array)

        self.port_mappings = arg.collect do |item|
          app_protocol, port = item.split('/')

          PortMapping.new(
            app_protocol: app_protocol,
            container_port: port,
            host_port: port,
            protocol: 'tcp'
          )
        end
      end

      def load_balancers=(arg)
        super(
          if arg.is_a?(Array)
            arg.collect do |item|
              case item
              when Hash then LoadBalancer.new(item.transform_keys(&:to_sym))
              when LoadBalancer then item
              else
                raise "Invalid load balancer entry: #{item}"
              end
            end
          else
            []
          end
        )
      end

      class PortMapping < Model
        PORT_PROTOCOLS = %w[grpc http http2].freeze

        # @!attribute app_protocol
        #   @return [String]
        attribute :app_protocol, :string

        # @!attribute container_port
        #   @return [Integer]
        attribute :container_port, :integer

        # @!attribute host_port
        #   @return [Integer]
        attribute :host_port, :integer

        # @!attribute protocol
        #   @return [Integer]
        attribute :protocol, :string
      end

      class LoadBalancer < Model
        # @!attribute port
        #   @return [Integer]
        attribute :port, :integer

        # @!attribute target_group
        #   @return [String]
        attribute :target_group, :string
      end
    end
  end
end
