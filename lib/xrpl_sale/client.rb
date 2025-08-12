# frozen_string_literal: true

module XRPLSale
  # Main client for interacting with the XRPL.Sale API
  #
  # The client provides access to all platform services including projects,
  # investments, analytics, webhooks, and authentication.
  #
  # @example Creating a client
  #   client = XRPLSale::Client.new(
  #     api_key: "your-api-key",
  #     environment: :production
  #   )
  #
  # @example Using services
  #   projects = client.projects.list(status: "active")
  #   project = client.projects.get("proj_123")
  #   investment = client.investments.create(project_id: "proj_123", amount_xrp: "100")
  class Client
    # Default request timeout in seconds
    DEFAULT_TIMEOUT = 30

    # Default maximum retry attempts
    DEFAULT_MAX_RETRIES = 3

    # Default retry delay in seconds
    DEFAULT_RETRY_DELAY = 1

    attr_reader :config, :connection
    attr_accessor :auth_token

    # Initialize a new client
    #
    # @param api_key [String] The API key for authentication
    # @param environment [Symbol, String] The environment (:production or :testnet)
    # @param base_url [String] Custom base URL (optional)
    # @param timeout [Integer] Request timeout in seconds
    # @param max_retries [Integer] Maximum retry attempts
    # @param retry_delay [Integer] Delay between retries in seconds
    # @param webhook_secret [String] Secret for webhook signature verification
    # @param debug [Boolean] Enable debug logging
    def initialize(
      api_key: nil,
      environment: :production,
      base_url: nil,
      timeout: DEFAULT_TIMEOUT,
      max_retries: DEFAULT_MAX_RETRIES,
      retry_delay: DEFAULT_RETRY_DELAY,
      webhook_secret: nil,
      debug: false
    )
      @config = {
        api_key: api_key,
        environment: environment.to_sym,
        base_url: base_url || default_base_url(environment),
        timeout: timeout,
        max_retries: max_retries,
        retry_delay: retry_delay,
        webhook_secret: webhook_secret,
        debug: debug
      }

      @connection = build_connection
      @auth_token = nil
    end

    # Get the projects service
    #
    # @return [Services::Projects] The projects service
    def projects
      @projects ||= Services::Projects.new(self)
    end

    # Get the investments service
    #
    # @return [Services::Investments] The investments service
    def investments
      @investments ||= Services::Investments.new(self)
    end

    # Get the analytics service
    #
    # @return [Services::Analytics] The analytics service
    def analytics
      @analytics ||= Services::Analytics.new(self)
    end

    # Get the webhooks service
    #
    # @return [Services::Webhooks] The webhooks service
    def webhooks
      @webhooks ||= Services::Webhooks.new(self)
    end

    # Get the auth service
    #
    # @return [Services::Auth] The auth service
    def auth
      @auth ||= Services::Auth.new(self)
    end

    # Make a GET request
    #
    # @param endpoint [String] The API endpoint
    # @param params [Hash] Query parameters
    # @return [Hash] The response data
    # @raise [Error] If the request fails
    def get(endpoint, params = {})
      request(:get, endpoint, params: params)
    end

    # Make a POST request
    #
    # @param endpoint [String] The API endpoint
    # @param data [Hash] Request body data
    # @return [Hash] The response data
    # @raise [Error] If the request fails
    def post(endpoint, data = {})
      request(:post, endpoint, json: data)
    end

    # Make a PUT request
    #
    # @param endpoint [String] The API endpoint
    # @param data [Hash] Request body data
    # @return [Hash] The response data
    # @raise [Error] If the request fails
    def put(endpoint, data = {})
      request(:put, endpoint, json: data)
    end

    # Make a PATCH request
    #
    # @param endpoint [String] The API endpoint
    # @param data [Hash] Request body data
    # @return [Hash] The response data
    # @raise [Error] If the request fails
    def patch(endpoint, data = {})
      request(:patch, endpoint, json: data)
    end

    # Make a DELETE request
    #
    # @param endpoint [String] The API endpoint
    # @return [Hash] The response data
    # @raise [Error] If the request fails
    def delete(endpoint)
      request(:delete, endpoint)
    end

    # Verify a webhook signature
    #
    # @param payload [String] The raw webhook payload
    # @param signature [String] The signature from the header
    # @param secret [String] Custom secret (optional, uses client secret by default)
    # @return [Boolean] True if the signature is valid
    def verify_webhook_signature(payload, signature, secret = nil)
      secret_to_use = secret || config[:webhook_secret]
      XRPLSale.verify_webhook_signature(payload, signature, secret_to_use)
    end

    # Parse a webhook event
    #
    # @param payload [String] The JSON webhook payload
    # @return [WebhookEvent] The parsed webhook event
    def parse_webhook_event(payload)
      XRPLSale.parse_webhook_event(payload)
    end

    private

    # Make an HTTP request
    #
    # @param method [Symbol] HTTP method
    # @param endpoint [String] API endpoint
    # @param options [Hash] Request options
    # @return [Hash] Response data
    # @raise [Error] If the request fails
    def request(method, endpoint, options = {})
      response = connection.public_send(method, endpoint) do |req|
        req.headers["User-Agent"] = "XRPL.Sale-Ruby-SDK/#{VERSION}"
        req.headers["Accept"] = "application/json"
        req.headers["Content-Type"] = "application/json" if [:post, :put, :patch].include?(method)

        # Add authentication
        if auth_token
          req.headers["Authorization"] = "Bearer #{auth_token}"
        elsif config[:api_key]
          req.headers["X-API-Key"] = config[:api_key]
        end

        # Add request data
        req.params = options[:params] if options[:params]
        req.body = options[:json].to_json if options[:json]
      end

      handle_response(response)
    rescue Faraday::Error => e
      raise Error.new("Request failed: #{e.message}")
    end

    # Handle the HTTP response
    #
    # @param response [Faraday::Response] The HTTP response
    # @return [Hash] The parsed response data
    # @raise [Error] If the response indicates an error
    def handle_response(response)
      case response.status
      when 200..299
        parse_response_body(response.body)
      when 400
        raise ValidationError.from_response(response)
      when 401
        raise AuthenticationError.from_response(response)
      when 404
        raise NotFoundError.from_response(response)
      when 429
        raise RateLimitError.from_response(response)
      else
        raise Error.from_response(response)
      end
    end

    # Parse the response body
    #
    # @param body [String] The response body
    # @return [Hash] The parsed data
    def parse_response_body(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError => e
      raise Error.new("Invalid JSON response: #{e.message}")
    end

    # Build the Faraday connection
    #
    # @return [Faraday::Connection] The HTTP connection
    def build_connection
      Faraday.new(config[:base_url]) do |f|
        # Request/response middleware
        f.request :json
        f.response :json, symbolize_names: true

        # Retry middleware
        if config[:max_retries] > 0
          f.request :retry,
                    max: config[:max_retries],
                    interval: config[:retry_delay],
                    backoff_factor: 2,
                    retry_statuses: [429, 500, 502, 503, 504],
                    methods: [:get, :post, :put, :patch, :delete]
        end

        # Logging
        if config[:debug]
          f.response :logger, nil, { headers: true, bodies: true }
        end

        # HTTP adapter
        f.adapter :net_http
      end
    end

    # Get the default base URL for an environment
    #
    # @param environment [Symbol, String] The environment
    # @return [String] The base URL
    def default_base_url(environment)
      case environment.to_sym
      when :testnet
        TESTNET_URL
      else
        PRODUCTION_URL
      end
    end
  end
end