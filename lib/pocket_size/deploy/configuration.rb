# frozen_string_literal: true

module PocketSize
  module Deploy
    class Configuration < Model
      # @!attribute name
      #   @return [String]
      attribute :name, :string

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

      # @!attribute secrets
      #   @return [Array<String>]
      attribute :secrets, default: -> { Array.new }

      # @param filepath [String]
      # @return [PocketSize::Deploy::Configuration]
      def self.from_file(filepath)
        yaml_data = YAML.load_file(filepath)
        new(yaml_data.transform_keys(&:to_sym))
      end

      # @return [void]
      def image=(arg)
        super(
          case arg
          when Hash then ImageModel.from_json(arg)
          when PocketSize::Deploy::Configuration::ImageModel then arg
          end
        )
      end

      # @return [void]
      def aws=(arg)
        super(
          case arg
          when Hash then AwsModel.from_json(arg)
          when PocketSize::Deploy::Configuration::AwsModel then arg
          end
        )
      end

      # @return [void]
      def vpc=(arg)
        super(
          case arg
          when Hash then VpcModel.from_json(arg)
          when PocketSize::Deploy::Configuration::VpcModel then arg
          end
        )
      end

      class ImageModel < Model
        # @!attribute arch
        #   @return [String]
        attribute :arch, :string

        # @!attribute entrypoint
        #   @return [Array<String>]
        attribute :entrypoint

        # @param json [Hash{String => Object}]
        # @return [PocketSize::Deploy::Configuration::ImageModel]
        def self.from_json(json)
          new(arch: json['arch'], entrypoint: json['entrypoint'])
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

        # @param json [Hash{String => Object}]
        # @return [PocketSize::Deploy::Configuration::AwsModel]
        def self.from_json(json)
          new(region: json['region'])
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
    end
  end
end
