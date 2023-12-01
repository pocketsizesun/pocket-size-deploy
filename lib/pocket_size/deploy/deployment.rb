# frozen_string_literal: true

module PocketSize
  module Deploy
    class Deployment
      def self.deploy!(configuration_path, **kwargs)
        new(configuration_path, **kwargs).deploy!
      end

      def initialize(configuration_path, dry_run: false, skip_container: false, skip_deploy: false, rebuild: false, force: false, dev_build_number: true)
        @configuration_path = configuration_path
        @dry_run = dry_run
        @skip_container = skip_container
        @skip_deploy = skip_deploy
        @rebuild = rebuild
        @force = force
        @dev_build_number = dev_build_number
      end

      def deploy!
        @configuration = PocketSize::Deploy::Configuration.from_file(
          @configuration_path
        )

        # if app version is a dev one, append build number to it
        if Gem::Version.new(@configuration.version).segments.last == 'dev'
          @configuration.version = "#{@configuration.version}.#{Time.now.strftime('%Y%m%d%H%M%S')}"
        end

        unless @configuration.aws.profile.nil?
          ENV['AWS_PROFILE'] = @configuration.aws.profile
        end

        # resolve services' target groups
        # @param service [PocketSize::Deploy::ServiceDefinition]
        @elb_client = Aws::ElasticLoadBalancingV2::Client.new
        @configuration.services.each_value do |service|
          service.load_balancers.each do |load_balancer|
            next if load_balancer.target_group.nil?

            begin
              result = @elb_client.describe_target_groups(names: [load_balancer.target_group])
              raise 'not found' if result.target_groups.empty?
            rescue StandardError, Aws::ElasticLoadBalancingV2::Errors::TargetGroupNotFoundException
              abort "Unable to find '#{load_balancer.target_group}' target group for service '#{service.name}'"
            end

            load_balancer.target_group_arn = result.target_groups[0].target_group_arn
          end
        end

        # resolve secrets if DYNAMIC strategy enabled
        unless @configuration.secrets.nil?
          if @configuration.secrets.strategy == 'DYNAMIC'
            @ssm_client = Aws::SSM::Client.new
            get_parameters_by_path_parameters = {
              path: format('/%s/', @configuration.secrets.prefix || @configuration.name),
              recursive: false,
              with_decryption: false
            }
            parameter_names = Set.new

            loop do
              result = @ssm_client.get_parameters_by_path(
                get_parameters_by_path_parameters
              )
              result.parameters.each do |parameter|
                parameter_names << parameter.name.split('/').last
              end
              break if result.next_token.nil?

              get_parameters_by_path_parameters[:next_token] = result.next_token
            end

            @configuration.secrets.parameters = parameter_names.to_a - @configuration.secrets.exclude
          end
        end

        @ecr_client = Aws::ECR::Client.new
        @ecr_image_exists = ecr_image_exists?
        @ecr_image_latest_version = ecr_image_latest_version
        confirm_deploy!

        # get aws account id
        @aws_account_id = `aws sts get-caller-identity --query 'Account' --output text --no-cli-pager`.strip
        @image_tag = format('%s:%s', @configuration.name, @configuration.version)
        @ecr_endpoint = format('%s.dkr.ecr.%s.amazonaws.com', @aws_account_id, @configuration.aws.region)
        @ecr_image_url = format('%s/%s', @ecr_endpoint, @image_tag)

        # run prebuild hooks
        @configuration.hooks['prebuild']&.each do |cmd|
          puts "|> execute prebuild hook: #{cmd}"
          execute(cmd)
        end

        # build image
        if @rebuild == true || (@ecr_image_exists == false && @skip_container == false)
          docker_build_args = [
            '--platform', @configuration.image.docker_platform,
            '-t', @image_tag,
            '-f', "Dockerfile"
          ]
          unless @configuration.image.target.nil?
            docker_build_args << '--target'
            docker_build_args << @configuration.image.target
          end

          execute(format('docker buildx build %s .', docker_build_args.join(' ')))
          execute(format('aws ecr get-login-password --region %s | docker login --username AWS --password-stdin "%s"', @configuration.aws.region, @ecr_endpoint))
          execute(format('docker tag "%s" "%s"', @image_tag, @ecr_image_url))
          execute(format('docker push %s', @ecr_image_url))
          execute(format('docker rmi "%s"', @image_tag))
          execute(format('docker rmi "%s"', @ecr_image_url))

          if @dry_run == false
            ecr_batch_get_image_result = @ecr_client.batch_get_image(
              repository_name: @configuration.name,
              image_ids: [{ image_tag: @configuration.version }]
            )

            # get pushed image details
            ecr_image = ecr_batch_get_image_result.images.first

            # tag latest image with 'latest' tag
            @ecr_client.put_image(
              repository_name: @configuration.name,
              image_manifest: ecr_image.image_manifest,
              image_tag: 'latest'
            )
          end
        end

        if @skip_deploy == false
          cf_template = PocketSize::Deploy::CloudFormationTemplate.render(
            @configuration
          )

          tempfile = Tempfile.new(['template', '.yml'])
          tempfile.write(cf_template)
          tempfile.flush
          tempfile.rewind

          if @dry_run == true
            puts '[DRY-RUN] CloudFormation template'
            puts '---------------------------------'
            puts cf_template
            puts '---------------------------------'
          end

          execute(
            format(
              'aws cloudformation deploy --stack-name %s --template-file %s --parameter-overrides "ImageTag=%s"',
              @configuration.stack_name || "#{@configuration.name}-ecs",
              tempfile.path,
              @configuration.version
            )
          )
          tempfile.close
        end

        return true
      end

      private

      def execute(cmd)
        if @dry_run == true
          puts "[DRY-RUN] Execute command: #{cmd}"
        else
          system(ENV, cmd)
          abort "Command failed: #{cmd}" unless $?.exitstatus == 0
        end
      end

      def confirm_deploy!
        highline = HighLine.new

        puts "!!!! PLEASE REVIEW AWS ACCOUNT DETAILS !!!!"
        print 'NAME: '
        puts `aws iam list-account-aliases --query "AccountAliases[0]" --no-cli-pager --output text`.strip
        print '  ID: '
        puts `aws sts get-caller-identity --query "Account" --no-cli-pager --output text`.strip
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

        puts '' # empty line

        if @ecr_image_exists == true
          puts '******** NOTICE *********'
          puts "Docker image version '#{@configuration.version}' already exists."
          puts 'Image will not be rebuilt/pushed.'
          puts 'Only CloudFormation template will be deployed.'
          puts '*************************'
          puts ''
        else
          unless @ecr_image_latest_version.nil?
            begin
              deploy_version = Gem::Version.new(@configuration.version)
              latest_version = Gem::Version.new(@ecr_image_latest_version)

              if deploy_version < latest_version
                puts '******* WARNING ********'
                puts "You are deploying version '#{deploy_version}' but latest is '#{latest_version}'"
                puts '************************'
                puts ''
                if @force == false
                  abort 'ABORTING. Use `--force` to deploy an older version.'
                end
              end
            rescue ArgumentError => e
              puts "[WARNING] unable to parse version, error: #{e.message}"
            end
          end
        end

        puts '--------------------------------------------'
        puts ''

        puts "Are you sure you want to deploy '#{@configuration.name}' version '#{@configuration.version}'."
        answer = highline.ask("Press 'Y' to confirm: ") do |q|
          q.character = true
        end
        if answer.upcase == 'Y'
          puts 'Starting in 5 seconds...' if @dry_run == false
          sleep 5
        else
          puts '>>>>> Deploy aborted.'
          exit
        end
      end

      def ecr_image_exists?
        result = @ecr_client.describe_images(
          repository_name: @configuration.name,
          max_results: 100
        )

        found = result.image_details.find do |image_detail|
          !image_detail.image_tags.nil? &&
            !image_detail.image_tags.empty? &&
            image_detail.image_tags[0] == @configuration.version
        end

        !found.nil?
      end

      def ecr_image_latest_version
        result = @ecr_client.describe_images(
          repository_name: @configuration.name,
          max_results: 100
        )
        return if result.image_details.empty?

        sorted_image_details = result.image_details.sort_by(&:image_pushed_at)
        return if sorted_image_details.last.nil?
        return if sorted_image_details.last.image_tags.nil?
        return if sorted_image_details.last.image_tags.empty?

        sorted_image_details.last.image_tags.find do |item|
          item != 'latest'
        end
      end
    end
  end
end
