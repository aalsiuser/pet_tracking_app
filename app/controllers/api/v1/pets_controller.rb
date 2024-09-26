# frozen_string_literal: true

module Api
  module V1
    # Controller to receive pet tracking information from trackers and also to query stored tracking information
    class PetsController < ApplicationController
      rescue_from Dry::Types::ConstraintError do |e|
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # GET /api/v1/pets
      def index
        result = SearchPets.new(**filter_params).call

        render json: result
      end

      # POST /api/v1/pets
      def create
        CreatePet.new(**create_params).call
        render json: :success, status: :created
      rescue KeyError => e
        render json: { error: e.message }, status: :bad_request
      end

      # GET /api/v1/pets
      def show
        result = SearchPets.new(**search_params).call

        render json: result
      end

      # GET /api/v1/pets/count
      def count
        result = CountPets.new(**filter_params).call

        render json: result
      end

      private

      def create_params
        params.require(:pet).permit(:pet_type, :tracker_type, :owner_id, :in_zone, :lost_tracker).to_h.symbolize_keys
      end

      def filter_params
        params.permit(:pet_type, :tracker_type).to_h.symbolize_keys
      end

      def search_params
        params.permit(:id, :pet_type, :tracker_type).to_h.symbolize_keys
      end
    end
  end
end
