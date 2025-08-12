# frozen_string_literal: true

require "zeitwerk"
require "faraday"
require "faraday/retry"
require "faraday/net_http"
require "active_support/core_ext/hash"
require "active_support/core_ext/string"
require "openssl"
require "json"

# Main module for the XRPL.Sale Ruby SDK
#
# This SDK provides comprehensive integration with the XRPL.Sale platform,
# including project management, investment tracking, analytics, webhooks,
# and authentication services.
#
# @example Basic usage
#   client = XRPLSale::Client.new(api_key: "your-api-key")
#   projects = client.projects.list(status: "active")
#
# @example Rails integration
#   # In config/application.rb
#   config.xrpl_sale.api_key = Rails.application.credentials.xrpl_sale_api_key
#
module XRPLSale
  # SDK version
  VERSION = "1.0.0"

  # API environments
  PRODUCTION_URL = "https://api.xrpl.sale/v1"
  TESTNET_URL = "https://api-testnet.xrpl.sale/v1"

  # Setup Zeitwerk autoloader
  loader = Zeitwerk::Loader.for_gem
  loader.setup

  # Configuration singleton
  class << self
    attr_accessor :configuration
  end

  # Configure the SDK globally
  #
  # @yield [configuration] The configuration object
  # @yieldparam configuration [Configuration] The configuration instance
  #
  # @example
  #   XRPLSale.configure do |config|
  #     config.api_key = "your-api-key"
  #     config.environment = :production
  #     config.webhook_secret = "your-webhook-secret"
  #   end
  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    configuration
  end

  # Get the current configuration
  #
  # @return [Configuration] The current configuration
  def self.config
    configuration || configure
  end

  # Create a new client with default configuration
  #
  # @param options [Hash] Client options
  # @return [Client] A new client instance
  def self.client(options = {})
    Client.new(**config.to_h.merge(options))
  end

  # Verify a webhook signature
  #
  # @param payload [String] The raw webhook payload
  # @param signature [String] The signature from the X-XRPL-Sale-Signature header
  # @param secret [String] The webhook secret
  # @return [Boolean] True if the signature is valid
  def self.verify_webhook_signature(payload, signature, secret)
    return false if secret.nil? || secret.empty?

    expected_signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    Rack::Utils.secure_compare(expected_signature, signature)
  end

  # Parse a webhook event
  #
  # @param payload [String] The JSON webhook payload
  # @return [WebhookEvent] The parsed webhook event
  # @raise [JSON::ParserError] If the payload is invalid JSON
  def self.parse_webhook_event(payload)
    data = JSON.parse(payload, symbolize_names: true)
    WebhookEvent.new(data)
  end
end

# Load Rails integration if Rails is available
if defined?(Rails)
  require "xrpl_sale/railtie"
end