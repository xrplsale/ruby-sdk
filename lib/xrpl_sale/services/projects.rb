# frozen_string_literal: true

module XRPLSale
  module Services
    # Service for managing token sale projects
    #
    # This service provides methods for creating, updating, launching, and managing
    # token sale projects on the XRPL.Sale platform. It also includes functionality
    # for retrieving project statistics, investors, and tier information.
    #
    # @example List active projects
    #   projects = client.projects.list(status: "active", page: 1, limit: 10)
    #
    # @example Get a specific project
    #   project = client.projects.get("proj_123")
    #
    # @example Create a new project
    #   project = client.projects.create(
    #     name: "My DeFi Protocol",
    #     description: "Revolutionary DeFi protocol on XRPL",
    #     token_symbol: "MDP",
    #     total_supply: "100000000"
    #   )
    class Projects < Base
      # List all projects with optional filtering and pagination
      #
      # @param status [String] Filter by project status
      # @param page [Integer] Page number (1-based)
      # @param limit [Integer] Number of items per page
      # @param sort_by [String] Field to sort by
      # @param sort_order [String] Sort order (asc or desc)
      # @return [Hash] Paginated response with project data
      # @raise [Error] If the API request fails
      def list(status: nil, page: nil, limit: nil, sort_by: nil, sort_order: nil)
        params = {}
        params[:status] = status if status
        params[:page] = page if page
        params[:limit] = limit if limit
        params[:sort_by] = sort_by if sort_by
        params[:sort_order] = sort_order if sort_order

        client.get("/projects", params)
      end

      # Get active projects
      #
      # @param page [Integer] Page number (1-based)
      # @param limit [Integer] Number of items per page
      # @return [Hash] Paginated response with active projects
      def active(page: 1, limit: 10)
        list(status: "active", page: page, limit: limit)
      end

      # Get upcoming projects
      #
      # @param page [Integer] Page number (1-based)
      # @param limit [Integer] Number of items per page
      # @return [Hash] Paginated response with upcoming projects
      def upcoming(page: 1, limit: 10)
        list(status: "upcoming", page: page, limit: limit)
      end

      # Get completed projects
      #
      # @param page [Integer] Page number (1-based)
      # @param limit [Integer] Number of items per page
      # @return [Hash] Paginated response with completed projects
      def completed(page: 1, limit: 10)
        list(status: "completed", page: page, limit: limit)
      end

      # Get a specific project by ID
      #
      # @param project_id [String] The project ID
      # @return [Hash] Project data
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [Error] If the API request fails
      def get(project_id)
        client.get("/projects/#{project_id}")
      end

      # Create a new project
      #
      # @param attributes [Hash] Project attributes
      # @option attributes [String] :name Project name
      # @option attributes [String] :description Project description
      # @option attributes [String] :token_symbol Token symbol
      # @option attributes [String] :total_supply Total token supply
      # @option attributes [Array<Hash>] :tiers Project tiers
      # @option attributes [String] :sale_start_date Sale start date (ISO 8601)
      # @option attributes [String] :sale_end_date Sale end date (ISO 8601)
      # @return [Hash] Created project data
      # @raise [ValidationError] If validation fails
      # @raise [Error] If the API request fails
      def create(**attributes)
        client.post("/projects", attributes)
      end

      # Update an existing project
      #
      # @param project_id [String] The project ID
      # @param attributes [Hash] Project attributes to update
      # @return [Hash] Updated project data
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [ValidationError] If validation fails
      # @raise [Error] If the API request fails
      def update(project_id, **attributes)
        client.patch("/projects/#{project_id}", attributes)
      end

      # Launch a project (make it active)
      #
      # @param project_id [String] The project ID
      # @return [Hash] Updated project data
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [Error] If the API request fails
      def launch(project_id)
        client.post("/projects/#{project_id}/launch")
      end

      # Pause a project
      #
      # @param project_id [String] The project ID
      # @return [Hash] Updated project data
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [Error] If the API request fails
      def pause(project_id)
        client.post("/projects/#{project_id}/pause")
      end

      # Resume a paused project
      #
      # @param project_id [String] The project ID
      # @return [Hash] Updated project data
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [Error] If the API request fails
      def resume(project_id)
        client.post("/projects/#{project_id}/resume")
      end

      # Cancel a project
      #
      # @param project_id [String] The project ID
      # @return [Hash] Updated project data
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [Error] If the API request fails
      def cancel(project_id)
        client.post("/projects/#{project_id}/cancel")
      end

      # Get project statistics
      #
      # @param project_id [String] The project ID
      # @return [Hash] Project statistics
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [Error] If the API request fails
      def stats(project_id)
        client.get("/projects/#{project_id}/stats")
      end

      # Get project investors
      #
      # @param project_id [String] The project ID
      # @param page [Integer] Page number (1-based)
      # @param limit [Integer] Number of items per page
      # @return [Hash] Paginated response with investor data
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [Error] If the API request fails
      def investors(project_id, page: 1, limit: 10)
        client.get("/projects/#{project_id}/investors", page: page, limit: limit)
      end

      # Get project tiers
      #
      # @param project_id [String] The project ID
      # @return [Array<Hash>] Project tiers
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [Error] If the API request fails
      def tiers(project_id)
        client.get("/projects/#{project_id}/tiers")
      end

      # Update project tiers
      #
      # @param project_id [String] The project ID
      # @param tiers [Array<Hash>] New tier configuration
      # @return [Array<Hash>] Updated tiers
      # @raise [NotFoundError] If the project doesn't exist
      # @raise [ValidationError] If validation fails
      # @raise [Error] If the API request fails
      def update_tiers(project_id, tiers)
        client.put("/projects/#{project_id}/tiers", tiers: tiers)
      end

      # Search projects
      #
      # @param query [String] Search query
      # @param status [String] Filter by status
      # @param page [Integer] Page number (1-based)
      # @param limit [Integer] Number of items per page
      # @return [Hash] Paginated response with matching projects
      # @raise [Error] If the API request fails
      def search(query, status: nil, page: 1, limit: 10)
        params = { q: query, page: page, limit: limit }
        params[:status] = status if status

        client.get("/projects/search", params)
      end

      # Get featured projects
      #
      # @param limit [Integer] Maximum number of projects to return
      # @return [Array<Hash>] Featured projects
      # @raise [Error] If the API request fails
      def featured(limit: 5)
        response = client.get("/projects/featured", limit: limit)
        response[:data] || []
      end

      # Get trending projects
      #
      # @param period [String] Time period (24h, 7d, 30d)
      # @param limit [Integer] Maximum number of projects to return
      # @return [Array<Hash>] Trending projects
      # @raise [Error] If the API request fails
      def trending(period: "24h", limit: 10)
        response = client.get("/projects/trending", period: period, limit: limit)
        response[:data] || []
      end
    end
  end
end