# XRPL.Sale Ruby SDK

Official Ruby SDK for integrating with the XRPL.Sale platform - the native XRPL launchpad for token sales and project funding.

[![Gem Version](https://badge.fury.io/rb/xrplsale.svg)](https://badge.fury.io/rb/xrplsale)
[![Ruby](https://img.shields.io/badge/Ruby-3.0+-red.svg)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 💎 **Modern Ruby 3.0+** - Built with modern Ruby features and best practices
- 🛤️ **Rails Integration** - Seamless integration with Ruby on Rails applications
- 🔐 **XRPL Wallet Authentication** - Wallet-based authentication support
- 📊 **Project Management** - Create, launch, and manage token sales
- 💰 **Investment Tracking** - Monitor investments and analytics
- 🔔 **Webhook Support** - Real-time event notifications with signature verification
- 📈 **Analytics & Reporting** - Comprehensive data insights
- 🛡️ **Error Handling** - Structured exception hierarchy
- 🔄 **Auto-retry Logic** - Resilient API calls with exponential backoff
- ⚡ **Thread Safe** - Safe for concurrent usage

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xrplsale'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install xrplsale
```

## Quick Start

### Basic Usage

```ruby
require 'xrpl_sale'

# Initialize the client
client = XRPLSale::Client.new(
  api_key: 'your-api-key',
  environment: :production # or :testnet
)

# Create a new project
project = client.projects.create(
  name: 'My DeFi Protocol',
  description: 'Revolutionary DeFi protocol on XRPL',
  token_symbol: 'MDP',
  total_supply: '100000000',
  tiers: [
    {
      tier: 1,
      price_per_token: '0.001',
      total_tokens: '20000000'
    }
  ],
  sale_start_date: '2025-02-01T00:00:00Z',
  sale_end_date: '2025-03-01T00:00:00Z'
)

puts "Project created: #{project[:id]}"
```

### Global Configuration

```ruby
XRPLSale.configure do |config|
  config.api_key = 'your-api-key'
  config.environment = :production
  config.webhook_secret = 'your-webhook-secret'
  config.debug = true
end

# Use the globally configured client
client = XRPLSale.client
projects = client.projects.list(status: 'active')
```

### Rails Integration

Add to your `config/application.rb`:

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # XRPL.Sale configuration
    config.xrpl_sale.api_key = Rails.application.credentials.xrpl_sale_api_key
    config.xrpl_sale.environment = :production
    config.xrpl_sale.webhook_secret = Rails.application.credentials.xrpl_sale_webhook_secret
    config.xrpl_sale.webhook_path = '/webhooks/xrplsale'
  end
end
```

Use in your Rails controllers and services:

```ruby
class ProjectsController < ApplicationController
  def index
    @projects = xrpl_sale_client.projects.list(status: 'active')
  end

  def show
    @project = xrpl_sale_client.projects.get(params[:id])
  rescue XRPLSale::NotFoundError
    redirect_to projects_path, alert: 'Project not found'
  end

  private

  def xrpl_sale_client
    @xrpl_sale_client ||= XRPLSale.client
  end
end
```

## Authentication

### XRPL Wallet Authentication

```ruby
# Generate authentication challenge
challenge = client.auth.generate_challenge('rYourWalletAddress...')

# Sign the challenge with your wallet
# (implementation depends on your wallet library)
signature = sign_message(challenge[:challenge])

# Authenticate
auth_response = client.auth.authenticate(
  wallet_address: 'rYourWalletAddress...',
  signature: signature,
  timestamp: challenge[:timestamp]
)

puts "Authentication successful: #{auth_response[:token]}"

# Set the auth token for subsequent requests
client.auth_token = auth_response[:token]
```

## Core Services

### Projects Service

```ruby
# List active projects
projects = client.projects.active(page: 1, limit: 10)

# Get project details
project = client.projects.get('proj_abc123')

# Launch a project
client.projects.launch('proj_abc123')

# Get project statistics
stats = client.projects.stats('proj_abc123')
puts "Total raised: #{stats[:total_raised_xrp]} XRP"

# Search projects
results = client.projects.search('DeFi', status: 'active')

# Get trending projects
trending = client.projects.trending(period: '24h', limit: 5)
```

### Investments Service

```ruby
# Create an investment
investment = client.investments.create(
  project_id: 'proj_abc123',
  amount_xrp: '100',
  investor_account: 'rInvestorAddress...'
)

# List investments for a project
investments = client.investments.by_project('proj_abc123', page: 1, limit: 10)

# Get investor summary
summary = client.investments.investor_summary('rInvestorAddress...')

# Simulate an investment
simulation = client.investments.simulate(
  project_id: 'proj_abc123',
  amount_xrp: '100'
)
puts "Expected tokens: #{simulation[:token_amount]}"
```

### Analytics Service

```ruby
# Get platform analytics
analytics = client.analytics.platform
puts "Total raised: #{analytics[:total_raised_xrp]} XRP"

# Get project-specific analytics
project_analytics = client.analytics.project(
  'proj_abc123',
  start_date: '2025-01-01',
  end_date: '2025-01-31'
)

# Get market trends
trends = client.analytics.market_trends('30d')

# Export data
export = client.analytics.export(
  type: 'projects',
  format: 'csv',
  start_date: '2025-01-01',
  end_date: '2025-01-31'
)
puts "Download URL: #{export[:download_url]}"
```

## Webhook Integration

### Rails Webhook Handling

Mount the webhook engine in your routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount XRPLSale::Engine, at: '/webhooks/xrplsale'
end
```

Create a webhook handler:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include XRPLSale::WebhookHandler

  private

  def handle_investment_created(event_data)
    # Process new investment
    Rails.logger.info "New investment: #{event_data[:amount_xrp]} XRP"
    
    # Send confirmation email
    InvestmentMailer.confirmation(event_data[:investor_email], event_data).deliver_later
  end

  def handle_project_launched(event_data)
    Rails.logger.info "Project launched: #{event_data[:project_id]}"
    
    # Notify team
    SlackNotifier.notify("Project #{event_data[:project_name]} has launched!")
  end

  def handle_tier_completed(event_data)
    Rails.logger.info "Tier #{event_data[:tier]} completed for project #{event_data[:project_id]}"
  end
end
```

### Manual Webhook Verification

```ruby
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def xrplsale
    payload = request.raw_post
    signature = request.headers['X-XRPL-Sale-Signature']
    
    unless XRPLSale.verify_webhook_signature(payload, signature, webhook_secret)
      render json: { error: 'Invalid signature' }, status: :unauthorized
      return
    end
    
    event = XRPLSale.parse_webhook_event(payload)
    
    case event.type
    when 'investment.created'
      handle_new_investment(event.data)
    when 'project.launched'
      handle_project_launched(event.data)
    when 'tier.completed'
      handle_tier_completed(event.data)
    end
    
    render json: { status: 'ok' }
  end

  private

  def webhook_secret
    Rails.application.credentials.xrpl_sale_webhook_secret
  end

  def handle_new_investment(data)
    # Process the investment
    puts "New investment: #{data[:amount_xrp]} XRP"
  end
end
```

### Rack Middleware

For non-Rails applications:

```ruby
# config.ru
require 'xrpl_sale'

use XRPLSale::Middleware::WebhookHandler, 
    path: '/webhooks/xrplsale',
    secret: ENV['XRPLSALE_WEBHOOK_SECRET']

run MyApp
```

## Error Handling

```ruby
begin
  project = client.projects.get('invalid-id')
rescue XRPLSale::NotFoundError
  puts 'Project not found'
rescue XRPLSale::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue XRPLSale::ValidationError => e
  puts "Validation error: #{e.message}"
  puts "Details: #{e.details}"
rescue XRPLSale::RateLimitError => e
  puts "Rate limit exceeded. Retry after: #{e.retry_after} seconds"
rescue XRPLSale::Error => e
  puts "API error: #{e.message}"
  puts "Status: #{e.status_code}"
end
```

## Configuration Options

```ruby
client = XRPLSale::Client.new(
  api_key: 'your-api-key',              # Required
  environment: :production,             # :production or :testnet
  base_url: 'https://custom-api.com',   # Custom API URL (optional)
  timeout: 30,                          # Request timeout in seconds
  max_retries: 3,                       # Maximum retry attempts
  retry_delay: 1,                       # Base delay between retries
  webhook_secret: 'your-secret',        # For webhook verification
  debug: false                          # Enable debug logging
)
```

## Pagination

```ruby
# Manual pagination
response = client.projects.list(
  status: 'active',
  page: 1,
  limit: 50,
  sort_by: 'created_at',
  sort_order: 'desc'
)

response[:data].each do |project|
  puts "Project: #{project[:name]}"
end

puts "Page #{response[:pagination][:page]} of #{response[:pagination][:total_pages]}"
puts "Total projects: #{response[:pagination][:total]}"

# Automatic pagination with enumerator
projects = client.projects.each(status: 'active')
projects.take(100).each do |project|
  puts "Project: #{project[:name]}"
end
```

## Testing

```bash
# Run tests
bundle exec rspec

# Run tests with coverage
bundle exec rspec --coverage

# Run linting
bundle exec rubocop

# Run type checking (if using RBS)
bundle exec steep check
```

## Development

```bash
# Clone the repository
git clone https://github.com/xrplsale/ruby-sdk.git
cd ruby-sdk

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run console
bundle exec irb -r xrpl_sale

# Build gem
bundle exec rake build

# Install locally
bundle exec rake install
```

## Rails Generators

Generate configuration files:

```bash
# Generate initializer
rails generate xrpl_sale:install

# Generate webhook controller
rails generate xrpl_sale:webhook
```

This creates:

```ruby
# config/initializers/xrpl_sale.rb
XRPLSale.configure do |config|
  config.api_key = Rails.application.credentials.xrpl_sale_api_key
  config.environment = Rails.env.production? ? :production : :testnet
  config.webhook_secret = Rails.application.credentials.xrpl_sale_webhook_secret
end

# app/controllers/xrpl_sale_webhooks_controller.rb
class XrplSaleWebhooksController < ApplicationController
  include XRPLSale::WebhookHandler
  
  # Webhook event handlers are automatically called
end
```

## Support

- 📖 [Documentation](https://xrpl.sale/docs)
- 💬 [Discord Community](https://discord.gg/xrpl-sale)
- 🐛 [Issue Tracker](https://github.com/xrplsale/ruby-sdk/issues)
- 📧 [Email Support](mailto:developers@xrpl.sale)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- [XRPL.Sale Platform](https://xrpl.sale)
- [API Documentation](https://xrpl.sale/api-reference)
- [Other SDKs](https://xrpl.sale/documentation/developers/sdk-downloads)
- [GitHub Organization](https://github.com/xrplsale)

---

Made with ❤️ by the XRPL.Sale team