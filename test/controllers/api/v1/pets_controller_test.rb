# frozen_string_literal: true

require 'test_helper'
require 'mock_redis'

module APi
  module V1
    class PetsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @data = [
          { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true, lost_tracker: false },
          { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: true },
          { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false },
          { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: true },

          { pet_type: 'cat', tracker_type: 'small', owner_id: 2, in_zone: true, lost_tracker: false },
          { pet_type: 'dog', tracker_type: 'medium', owner_id: 2, in_zone: true },
          { pet_type: 'dog', tracker_type: 'medium', owner_id: 2, in_zone: false },
          { pet_type: 'cat', tracker_type: 'small', owner_id: 2, in_zone: true, lost_tracker: false },

          { pet_type: 'cat', tracker_type: 'big', owner_id: 3, in_zone: true, lost_tracker: false },
          { pet_type: 'dog', tracker_type: 'big', owner_id: 3, in_zone: true },
          { pet_type: 'dog', tracker_type: 'big', owner_id: 3, in_zone: false },
          { pet_type: 'cat', tracker_type: 'big', owner_id: 3, in_zone: false, lost_tracker: false }
        ]

        @data.each { |param| CreatePet.new(**param).call }
      end

      test '#index returns list of pet tracking info of all the pets' do
        get '/api/v1/pets'

        assert_equal(12, JSON.parse(response.body).size)
      end

      test '#index with tracker_type params returns pet data filtered by tracker_type' do
        get '/api/v1/pets', params: { tracker_type: 'small' }

        assert_equal(6, JSON.parse(response.body).size)
        assert_equal(['small'], JSON.parse(response.body).pluck('tracker_type').uniq)
      end

      test '#index with pet_type params returns pet data filtered with pet_type' do
        get '/api/v1/pets', params: { pet_type: 'cat' }

        assert_equal(6, JSON.parse(response.body).size)
        assert_equal(['cat'], JSON.parse(response.body).pluck('pet_type').uniq)
      end

      test '#index with pet_type and tracker_type params returns pet data filtered with pet_type and tacker_type' do
        get '/api/v1/pets', params: { pet_type: 'dog', tracker_type: 'small' }

        assert_equal(2, JSON.parse(response.body).size)
        assert_equal([%w[small dog]],
                     JSON.parse(response.body).pluck('tracker_type', 'pet_type').uniq)
      end

      test '#index with invalid pet_type params return unprocessable_entity' do
        get '/api/v1/pets', params: { pet_type: 'horse' }

        assert_response(:unprocessable_entity)
        assert_equal('"horse" violates constraints (included_in?(["cat", "dog"], "horse") failed)',
                     JSON.parse(response.body)['error'])
      end

      test '#index with invalid tracker_type params return unprocessable_entity' do
        get '/api/v1/pets', params: { tracker_type: 'very big' }

        assert_response(:unprocessable_entity)
        assert_equal('"very big" violates constraints (included_in?(["small", "medium", "big"], "very big") failed)',
                     JSON.parse(response.body)['error'])
      end

      test '#create with valid params returns success' do
        post '/api/v1/pets',
             params: {
               pet: {
                 pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false
               }
             }, as: :json

        assert_response(:created)
        assert('success', response.body)
      end

      test '#create with invalid tracker_type returns unprocessable entity' do
        post '/api/v1/pets',
             params: {
               pet: {
                 pet_type: 'cat', tracker_type: 'very big', owner_id: 1, in_zone: false, lost_tracker: false
               }
             }, as: :json

        assert_response(:unprocessable_entity)
        assert_equal('"very big" violates constraints (included_in?(["small", "medium", "big"], "very big") failed)',
                     JSON.parse(response.body)['error'])
      end

      test '#create with invalid pet_type return unprocessable entity' do
        post '/api/v1/pets',
             params: {
               pet: {
                 pet_type: 'horse', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false
               }
             }, as: :json

        assert_response(:unprocessable_entity)
        assert_equal('"horse" violates constraints (included_in?(["cat", "dog"], "horse") failed)',
                     JSON.parse(response.body)['error'])
      end

      test '#create with invalid input returns bad request' do
        post '/api/v1/pets',
             params: {
               pet: {
                 tracker_type: 'small', owner_id: 8, in_zone: false, lost_tracker: false
               }
             }, as: :json

        assert_response(:bad_request)
      end

      test '#show with owner_id param returns list of owners pets data' do
        get '/api/v1/pets/1'

        assert_equal(4, JSON.parse(response.body).size)
      end

      test '#show with pet_type params returns list of owners pets data filtered by pet_type' do
        get '/api/v1/pets/1', params: { pet_type: 'dog' }

        assert_equal(2, JSON.parse(response.body).size)
        assert_equal(['dog'], JSON.parse(response.body).pluck('pet_type').uniq)
      end

      test '#show with tracker_type params returns list of owners pets data filtered by tracker_type' do
        get '/api/v1/pets/1', params: { tracker_type: 'small' }

        assert_equal(4, JSON.parse(response.body).size)
        assert_equal(['small'], JSON.parse(response.body).pluck('tracker_type').uniq)
      end

      test '#show with pet_type and tracker_type params return list of owners pets data filtered by both params' do
        get '/api/v1/pets/1', params: { tracker_type: 'small', pet_type: 'dog' }

        assert_equal(2, JSON.parse(response.body).size)
        assert_equal([%w[small dog]],
                     JSON.parse(response.body).pluck('tracker_type', 'pet_type').uniq)
      end

      test '#show with invalid pet_type params return unprocessable_entity' do
        get '/api/v1/pets/1', params: { pet_type: 'horse' }

        assert_response(:unprocessable_entity)
        assert_equal('"horse" violates constraints (included_in?(["cat", "dog"], "horse") failed)',
                     JSON.parse(response.body)['error'])
      end

      test '#show with invalid tracker_type params return unprocessable_entity' do
        get '/api/v1/pets/1', params: { tracker_type: 'very big' }

        assert_response(:unprocessable_entity)
        assert_equal('"very big" violates constraints (included_in?(["small", "medium", "big"], "very big") failed)',
                     JSON.parse(response.body)['error'])
      end

      test '#count returns list of grouped pets count which are outside of power saving zone' do
        get '/api/v1/pets/count'

        assert_equal([
                       { 'tracker_type' => 'small', 'pet_type' => 'dog', 'count' => 0 },
                       { 'tracker_type' => 'small', 'pet_type' => 'cat', 'count' => 1 },
                       { 'tracker_type' => 'medium', 'pet_type' => 'dog', 'count' => 1 },
                       { 'tracker_type' => 'big', 'pet_type' => 'dog', 'count' => 1 },
                       { 'tracker_type' => 'big', 'pet_type' => 'cat', 'count' => 1 }
                     ], JSON.parse(response.body))
      end

      test '#count with pet_type params returns list of grouped pets with count filterd by pet_type' do
        get '/api/v1/pets/count', params: { pet_type: 'cat' }

        assert_equal([
                       { 'tracker_type' => 'small', 'pet_type' => 'cat', 'count' => 1 },
                       { 'tracker_type' => 'big', 'pet_type' => 'cat', 'count' => 1 }
                     ], JSON.parse(response.body))
      end

      test '#count with tracker_type params returns list of grouped pets with count filterd by tracker_type' do
        get '/api/v1/pets/count', params: { tracker_type: 'big' }

        assert_equal([
                       { 'tracker_type' => 'big', 'pet_type' => 'dog', 'count' => 1 },
                       { 'tracker_type' => 'big', 'pet_type' => 'cat', 'count' => 1 }
                     ], JSON.parse(response.body))
      end

      test '#count with tracker_type and pet_type returns list of grouped pets with count filtered by both params' do
        get '/api/v1/pets/count', params: { pet_type: 'dog', tracker_type: 'medium' }

        assert_equal([
                       { 'tracker_type' => 'medium', 'pet_type' => 'dog', 'count' => 1 }
                     ], JSON.parse(response.body))
      end

      test '#count with invalid pet_type params return unprocessable_entity' do
        get '/api/v1/pets/count', params: { pet_type: 'horse' }

        assert_response(:unprocessable_entity)
        assert_equal('"horse" violates constraints (included_in?(["cat", "dog"], "horse") failed)',
                     JSON.parse(response.body)['error'])
      end

      test '#count with invalid tracker_type params return unprocessable_entity' do
        get '/api/v1/pets/count', params: { tracker_type: 'very big' }

        assert_response(:unprocessable_entity)
        assert_equal('"very big" violates constraints (included_in?(["small", "medium", "big"], "very big") failed)',
                     JSON.parse(response.body)['error'])
      end
    end
  end
end
