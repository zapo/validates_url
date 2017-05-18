require 'addressable/uri'
require 'active_model'
require 'active_support/i18n'
require 'public_suffix'
I18n.load_path += Dir[File.dirname(__FILE__) + "/locale/*.yml"]

module ActiveModel
  module Validations
    class UrlValidator < ActiveModel::EachValidator

      def initialize(options)
        options.reverse_merge!(:schemes => %w(http https))
        options.reverse_merge!(:message => :url)
        options.reverse_merge!(:no_local => false)
        options.reverse_merge!(:public_suffix => false)

        super(options)
      end

      def validate_each(record, attribute, value)
        schemes = [*options.fetch(:schemes)].map(&:to_s)
        begin
          uri = Addressable::URI.parse(value)
          valid = uri
          valid &&= validate_host_presence(uri)
          valid &&= validate_suffix(uri, options)
          valid &&= validate_no_local(uri, options)
          valid &&= validate_scheme_presence(uri, schemes)
          valid &&= validate_pre_query(uri)
          unless valid
            record.errors.add(attribute, options.fetch(:message), :value => value)
          end
        rescue Addressable::URI::InvalidURIError
          record.errors.add(attribute, options.fetch(:message), :value => value)
        end
      end

      def validate_host_presence(uri)
        uri.host && uri.host.length > 0
      end

      def validate_suffix(uri, options)
        !options.fetch(:public_suffix) || (PublicSuffix.valid?(uri.host, :default_rule => nil))
      end

      def validate_no_local(uri, options)
        !options.fetch(:no_local) || uri.host.include?('.')
      end

      def validate_scheme_presence(uri, schemes)
        schemes.include?(uri.scheme)
      end

      def validate_pre_query(uri)
        # URLs with queries should have a '/' before the '?'.
        uri.query.nil? || uri.path&.starts_with?('/')
      end

    end

    module ClassMethods
      # Validates whether the value of the specified attribute is valid url.
      #
      #   class Unicorn
      #     include ActiveModel::Validations
      #     attr_accessor :homepage, :ftpsite
      #     validates_url :homepage, :allow_blank => true
      #     validates_url :ftpsite, :schemes => ['ftp']
      #   end
      # Configuration options:
      # * <tt>:message</tt> - A custom error message (default is: "is not a valid URL").
      # * <tt>:allow_nil</tt> - If set to true, skips this validation if the attribute is +nil+ (default is +false+).
      # * <tt>:allow_blank</tt> - If set to true, skips this validation if the attribute is blank (default is +false+).
      # * <tt>:schemes</tt> - Array of URI schemes to validate against. (default is +['http', 'https']+)

      def validates_url(*attr_names)
        validates_with UrlValidator, _merge_attributes(attr_names)
      end
    end
  end
end
