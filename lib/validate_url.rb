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
          validate_suffix = !options.fetch(:public_suffix) || (uri && uri.host && PublicSuffix.valid?(uri.host, :default_rule => nil))
          validate_no_local = !options.fetch(:no_local) || uri.host.include?('.')
	  validate_pre_query = has_slash_before_query(uri)
	  validated = validate_suffix && validate_no_local && validate_pre_query
          unless uri && uri.host && schemes.include?(uri.scheme) && validated
            record.errors.add(attribute, options.fetch(:message), :value => value)
          end
        rescue Addressable::URI::InvalidURIError
          record.errors.add(attribute, options.fetch(:message), :value => value)
        end
      end

      def has_slash_before_query(uri)
	# URLs with queries should have a '/' at some point before the '?'.
	unless uri.query.nil?
	  has_authority = uri.authority
	  starts_with_slash = uri.path.first === '/'
	  ends_with_slash = uri.path.last === '/'
	  unless has_authority && starts_with_slash || has_authority.nil? && ends_with_slash
	    return false
	  end
	end
	return true
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
