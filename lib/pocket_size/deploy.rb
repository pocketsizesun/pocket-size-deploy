# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'json'
require 'tempfile'
require 'base32'
require 'active_model'
require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-ecr'
require 'aws-sdk-ssm'
require 'highline'
require_relative "deploy/version"
require_relative 'deploy/cloud_formation_template'
require_relative 'deploy/model'
require_relative 'deploy/configuration'
require_relative 'deploy/deployment'
require_relative 'deploy/task_definition'
require_relative 'deploy/scheduled_task_definition'
require_relative 'deploy/service_definition'

module PocketSize
  module Deploy
    class Error < StandardError; end
    # Your code goes here...
  end
end
