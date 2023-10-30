# frozen_string_literal: true

module PocketSize
  module Deploy
    class Configuration < Model
      # @!attribute name
      #   @return [String]
      attribute :name, :string

      # @!attribute stack_name
      #   @return [String, nil]
      attribute :stack_name, :string

      # @!attribute cluster
      #   @return [String]
      attribute :cluster, :string

      # @!attribute version
      #   @return [String]
      attribute :version, :string

      # @!attribute task_execution_role_name
      #   @return [String]
      attribute :task_execution_role_name, :string

      # @!attribute task_role_name
      #   @return [String]
      attribute :task_role_name, :string

      # @!attribute image
      #   @return [PocketSize::Deploy::Configuration::ImageModel, nil]
      attribute :image

      # @!attribute aws
      #   @return [PocketSize::Deploy::Configuration::AwsModel, nil]
      attribute :aws

      # @!attribute vpc
      #   @return [PocketSize::Deploy::Configuration::VpcModel, nil]
      attribute :vpc

      # @!attribute hooks
      #   @return [Hash{String => Array<String>, nil}]
      attribute :hooks, default: -> { Hash.new }

      # @!attribute services
      #   @return [Hash{String => PocketSize::Deploy::ServiceDefinition}]
      attribute :services, default: -> { Hash.new }

      # @!attribute scheduled_tasks
      #   @return [Hash{String => PocketSize::Deploy::ScheduledTaskDefinition}]
      attribute :scheduled_tasks, default: -> { Hash.new }

      # @!attribute secrets
      #   @return [SecretsModel, nil]
      attribute :secrets, default: nil

      # @!attribute environment
      #   @return [Hash{String => String}]
      attribute :environment, default: -> { Hash.new }

      # @param filepath [String]
      # @return [PocketSize::Deploy::Configuration]
      def self.from_file(filepath)
        yaml_data = YAML.load_file(filepath, aliases: true).compact

        new(
          {
            name: yaml_data['name'],
            stack_name: yaml_data['stack_name'],
            cluster: yaml_data['cluster'],
            version: yaml_data['version'],
            task_execution_role_name: yaml_data['task_execution_role_name'],
            task_role_name: yaml_data['task_role_name'],
            image: !yaml_data['image'].nil? ? ImageModel.from_json(yaml_data['image']) : nil,
            aws: !yaml_data['aws'].nil? ? AwsModel.from_json(yaml_data['aws']) : nil,
            vpc: !yaml_data['vpc'].nil? ? VpcModel.from_json(yaml_data['vpc']) : nil,
            hooks: yaml_data['hooks'],
            services: yaml_data['services']&.each_with_object({}) do |item, hash|
              hash[item[0]] = PocketSize::Deploy::ServiceDefinition.from_json(
                { 'name' => item[0] }.merge!(item[1])
              )
            end,
            scheduled_tasks: yaml_data['scheduled_tasks']&.each_with_object({}) do |item, hash|
              hash[item[0]] = PocketSize::Deploy::ScheduledTaskDefinition.new(
                { 'name' => item[0] }.merge!(item[1])
              )
            end,
            secrets: \
              case yaml_data['secrets']
              when Hash then SecretsModel.from_json(yaml_data['secrets'])
              when Array
                SecretsModel.new(
                  strategy: SecretsModel::STRATEGY_STATIC,
                  parameters: yaml_data['secrets'].map(&:to_s)
                )
              end,
            environment: yaml_data['environment']
          }.compact
        )
      end

      class ImageModel < Model
        # @!attribute arch
        #   @return [String]
        attribute :arch, :string

        # @!attribute os
        #   @return [String]
        attribute :os, :string

        # @!attribute target
        #   @return [String, nil]
        attribute :target, :string, default: nil

        # @!attribute entrypoint
        #   @return [Array<String>]
        attribute :entrypoint

        # @param json [Hash{String => Object}]
        # @return [PocketSize::Deploy::Configuration::ImageModel]
        def self.from_json(json)
          new(
            arch: json['arch']&.upcase,
            os: json['os']&.upcase,
            target: json['target'],
            entrypoint: json['entrypoint']
          )
        end

        # @return [String]
        def docker_platform
          build_type = []
          build_type << \
            case os
            when 'LINUX' then 'linux'
            else
              abort "invalid image os type: #{os}"
            end
          build_type << \
            case arch
            when 'ARM64' then 'arm64'
            else
              abort "invalid image cpu arch type: #{os}"
            end
          build_type.join('/')
        end

        def cpu_arch
          case arch
          when 'linux/arm64' then 'ARM64'
          else
            raise "unknown image arch: #{arch}"
          end
        end

        def os_family
          case arch
          when 'linux/arm64' then 'LINUX'
          else
            raise "unknown image arch: #{arch}"
          end
        end
      end

      class AwsModel < Model
        # @!attribute region
        #   @return [String]
        attribute :region, :string

        # @!attribute profile
        #   @return [String, nil]
        attribute :profile, :string

        # @param json [Hash{String => Object}]
        # @return [PocketSize::Deploy::Configuration::AwsModel]
        def self.from_json(json)
          new(
            region: json['region'],
            profile: json['profile']
          )
        end
      end

      class VpcModel < Model
        # @!attribute security_groups
        #   @return [Array<String>]
        attribute :security_groups

        # @!attribute subnets
        #   @return [Array<String>]
        attribute :subnets

        # @param json [Hash{String => Object}]
        # @return [PocketSize::Deploy::Configuration::VpcModel]
        def self.from_json(json)
          new(
            security_groups: json['security_groups'],
            subnets: json['subnets']
          )
        end
      end

      class SecretsModel < Model
        STRATEGY_DYNAMIC = 'DYNAMIC'
        STRATEGY_STATIC  = 'STATIC'

        # @!attribute strategy
        #   @return [String]
        attribute :strategy, :string, default: STRATEGY_DYNAMIC

        # @!attribute prefix
        #   @return [String]
        attribute :prefix, :string

        # @!attribute parameters
        #   @return [Array<String>, nil]
        attribute :parameters, default: -> { Array.new }

        # @!attribute exclude
        #   @return [Array<String>]
        attribute :exclude, default: -> { Array.new }

        def self.from_json(json)
          new(
            {
              strategy: json['strategy'],
              prefix: json['prefix'],
              parameters: json['parameters'],
              exclude: json['exclude']
            }.compact
          )
        end
      end
    end
  end
end
