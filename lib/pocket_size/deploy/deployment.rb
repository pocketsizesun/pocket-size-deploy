# frozen_string_literal: true

module PocketSize
  module Deploy
    class Deployment
      def self.deploy!(app_version, configuration_path, **kwargs)
        new(app_version, configuration_path, **kwargs).deploy!
      end

      def initialize(app_version, configuration_path, dry_run: false, skip_container: false)
        @app_version = app_version
        @configuration_path = configuration_path
        @dry_run = dry_run
        @skip_container = skip_container
      end

      def deploy!
        @configuration = PocketSize::Deploy::Configuration.from_file(
          @configuration_path
        )
        @configuration.version = @app_version

        service_definitions = []

        @configuration.services.each do |service_name, properties|
          service_definition = PocketSize::Deploy::ServiceDefinition.new(
            { name: service_name }.merge(
              properties.transform_keys(&:to_sym)
            )
          )

          service_definitions << service_definition
        end

        # get aws account id
        @aws_account_id = `aws sts get-caller-identity --query 'Account' --output text --no-cli-pager`.strip
        @image_tag = format('%s:%s', @configuration.name, @configuration.version)
        @ecr_endpoint = format('%s.dkr.ecr.%s.amazonaws.com', @aws_account_id, @configuration.aws.region)
        @ecr_image_url = format('%s/%s', @ecr_endpoint, @image_tag)

        # build image
        if @skip_container == false
          execute(format('docker buildx build --platform %s -t %s -f "Dockerfile" .', @configuration.image.arch, @image_tag))
          execute(format('aws ecr get-login-password --region %s | docker login --username AWS --password-stdin "%s"', @configuration.aws.region, @ecr_endpoint))
          execute(format('docker tag "%s" "%s"', @image_tag, @ecr_image_url))
          execute(format('docker push %s', @ecr_image_url))
          execute(format('docker rmi "%s"', @image_tag))
          execute(format('docker rmi "%s"', @ecr_image_url))
        end

        cf_template = PocketSize::Deploy::CloudFormationTemplate.render(
          @configuration, service_definitions
        )

        if @dry_run == true
          puts '[DRY-RUN] CloudFormation template'
          puts '---------------------------------'
          puts cf_template
          puts '---------------------------------'
        else
          tempfile = Tempfile.new([ 'template', '.yml' ])
          tempfile.write(cf_template)
          tempfile.flush
          tempfile.rewind
          execute(format('aws cloudformation deploy --stack-name %s --template-file %s', "#{@configuration.name}-ecs", tempfile.path))
          tempfile.close
        end
      end

      private

      def execute(cmd)
        if @dry_run == true
          puts "[DRY-RUN] Execute command: #{cmd}"
        else
          system(cmd)
          abort "Command failed: #{cmd}" unless $?.exitstatus == 0
        end
      end
    end
  end
end
