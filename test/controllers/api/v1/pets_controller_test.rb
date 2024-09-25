# frozen_string_literal: true

require 'test_helper'
require 'mock_redis'

module APi
  module V1
    class PetsControllerTest < ActionDispatch::IntegrationTest
      test '#create with valid input returns success' do
        post '/api/v1/pets',
             params: { pet: { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false } }, as: :json

        assert_response(:created)
        assert('success', response.body)
      end

      test '#create with invalid tracker_type returns unprocessable entity' do
        post '/api/v1/pets',
             params: { pet: { pet_type: 'cat', tracker_type: 'very big', owner_id: 1, in_zone: false, lost_tracker: false } }, as: :json

        assert_response(:unprocessable_entity)
      end

      test '#create with invalid pet_type return unprocessable entity' do
        post '/api/v1/pets',
             params: { pet: { pet_type: 'mouse', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false } }, as: :json

        assert_response(:unprocessable_entity)
      end

      test '#create with invalid input returns bad request' do
        post '/api/v1/pets',
             params: { pet: { tracker_type: 'small', owner_id: 8, in_zone: false, lost_tracker: false } }, as: :json

        assert_response(:bad_request)
      end

      test '#show with owner_id param returns list of owners pet entities' do
        params_list = [
          { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false },
          { pet_type: 'dog', tracker_type: 'medium', owner_id: 1, in_zone: false },
          { pet_type: 'dog', tracker_type: 'big', owner_id: 1, in_zone: false }
        ]
        params_list.each { |param| CreatePet.new(**param).call }
        get '/api/v1/pets/1'

        assert_equal(3, JSON.parse(response.body).size)
        assert_equal(params_list.map { |param| param.transform_keys(&:to_s) }, JSON.parse(response.body))
      end

      test '#show with pety_type params as dog returns list of owners pet dog info tracked by all trackers' do
        params_list = [
          { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: true },
          { pet_type: 'dog', tracker_type: 'medium', owner_id: 1, in_zone: false },
          { pet_type: 'dog', tracker_type: 'big', owner_id: 1, in_zone: true }
        ]
        params_list.each { |param| CreatePet.new(**param).call }
        get '/api/v1/pets/1', params: { pet_type: 'dog' }

        assert_equal(2, JSON.parse(response.body).size)
        assert_equal(['dog'], JSON.parse(response.body).pluck('pet_type').uniq)
      end

      test '#show with tracker_type params as small returns list of owners pet info tracked by small tracker' do
        params_list = [
          { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false },
          { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: false },
          { pet_type: 'dog', tracker_type: 'big', owner_id: 1, in_zone: false }
        ]
        params_list.each { |param| CreatePet.new(**param).call }
        get '/api/v1/pets/1', params: { tracker_type: 'small' }

        assert_equal(2, JSON.parse(response.body).size)
        assert_equal(['small'], JSON.parse(response.body).pluck('tracker_type').uniq)
      end

      test '#show with owner_id, pet_type and tracker_type params return list of filtered pet entities' do
        params_list = [
          { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false },
          { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: false },
          { pet_type: 'dog', tracker_type: 'big', owner_id: 1, in_zone: false }
        ]
        params_list.each { |param| CreatePet.new(**param).call }
        get '/api/v1/pets/1', params: { tracker_type: 'small', pet_type: 'dog' }

        assert_equal(1, JSON.parse(response.body).size)
        assert_equal([{ pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: false }.transform_keys(&:to_s)],
                     JSON.parse(response.body))
      end

      test '#count returns array of grouped pets count which are outside the power saving zone' do
        params_list = [
          { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true, lost_tracker: false },
          { pet_type: 'dog', tracker_type: 'small', owner_id: 2, in_zone: true },
          { pet_type: 'dog', tracker_type: 'big', owner_id: 1, in_zone: false },
          { pet_type: 'dog', tracker_type: 'medium', owner_id: 3, in_zone: false }
        ]
        params_list.each { |param| CreatePet.new(**param).call }
        get '/api/v1/pets/count'

        assert_equal([
                       { 'tracker_type' => 'small', 'pet_type' => 'cat', 'count' => 0 },
                       { 'tracker_type' => 'small', 'pet_type' => 'dog', 'count' => 0 },
                       { 'tracker_type' => 'big', 'pet_type' => 'dog', 'count' => 1 },
                       { 'tracker_type' => 'medium', 'pet_type' => 'dog', 'count' => 1 }
                     ], JSON.parse(response.body))
      end

      test '#count with big cal'
    end
  end
end
