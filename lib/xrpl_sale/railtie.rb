# frozen_string_literal: true

module XRPLSale
  # Rails integration for the XRPL.Sale SDK
  #
  # This railtie automatically configures the SDK when used in a Rails application.
  # It sets up configuration from Rails application config and provides
  # webhook handling middleware.
  #
  # @example Configuration in Rails
  #   # config/application.rb
  #   config.xrpl_sale.api_key = Rails.application.credentials.xrpl_sale_api_key
  #   config.xrpl_sale.environment = :production
  #   config.xrpl_sale.webhook_secret = Rails.application.credentials.xrpl_sale_webhook_secret
  #
  # @example Webhook handling
  #   # config/routes.rb
  #   Rails.application.routes.draw do
  #     mount XRPLSale::Engine, at: "/webhooks/xrplsale"
  #   end
  #
  #   # app/controllers/application_controller.rb
  #   class ApplicationController < ActionController::Base
  #     include XRPLSale::WebhookHandler
  #   
  #     private
  #   
  #     def handle_investment_created(event_data)
  #       # Process new investment
  #       Rails.logger.info "New investment: #{event_data[:amount_xrp]} XRP"
  #     end
  #   end
  class Railtie < ::Rails::Railtie
    config.xrpl_sale = ActiveSupport::OrderedOptions.new

    # Set default configuration values
    config.xrpl_sale.api_key = nil
    config.xrpl_sale.environment = :production
    config.xrpl_sale.webhook_secret = nil
    config.xrpl_sale.webhook_path = "/webhooks/xrplsale"
    config.xrpl_sale.timeout = 30
    config.xrpl_sale.max_retries = 3
    config.xrpl_sale.debug = false

    # Configure the SDK after Rails initialization
    initializer "xrpl_sale.configure" do |app|
      XRPLSale.configure do |sdk_config|
        rails_config = app.config.xrpl_sale

        sdk_config.api_key = rails_config.api_key
        sdk_config.environment = rails_config.environment
        sdk_config.webhook_secret = rails_config.webhook_secret
        sdk_config.timeout = rails_config.timeout
        sdk_config.max_retries = rails_config.max_retries
        sdk_config.debug = rails_config.debug
      end
    end

    # Add webhook handling middleware
    initializer "xrpl_sale.add_middleware" do |app|
      if app.config.xrpl_sale.webhook_path
        app.middleware.use XRPLSale::Middleware::WebhookHandler,
                           path: app.config.xrpl_sale.webhook_path
      end
    end

    # Add generators
    generators do
      require "xrpl_sale/generators/install_generator"
      require "xrpl_sale/generators/webhook_generator"
    end
  end

  # Rails engine for mounting webhook endpoints
  class Engine < ::Rails::Engine
    isolate_namespace XRPLSale

    # Define webhook routes
    routes.draw do
      post "/", to: "webhooks#handle"
    end
  end
end