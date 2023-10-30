# frozen_string_literal: true

module PocketSize
  module Deploy
    class Model
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::AttributeMethods

      # @!parse
      #   extend ActiveModel::Attributes::ClassMethods
      #   extend ActiveModel::AttributeMethods::ClassMethods
    end
  end
end
