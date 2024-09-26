# frozen_string_literal: true

require 'test_helper'

class CountPetsTest < ActiveSupport::TestCase
  def setup
    data = [
      { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true, lost_tracker: false },
      { pet_type: 'dog', tracker_type: 'small', owner_id: 2, in_zone: false },
      { pet_type: 'cat', tracker_type: 'medium', owner_id: 2, in_zone: false, lost_tracker: false },
      { pet_type: 'dog', tracker_type: 'medium', owner_id: 1, in_zone: true },
      { pet_type: 'dog', tracker_type: 'big', owner_id: 1, in_zone: false }
    ]

    data.each { |param| CreatePet.new(**param).call }
  end

  test 'call returns count of pets grouped by pet_type and tracker_type' do
    result = CountPets.new.call

    assert_equal([{ 'tracker_type' => 'small', 'pet_type' => 'cat', 'count' => 0 },
                  { 'tracker_type' => 'small', 'pet_type' => 'dog', 'count' => 1 },
                  { 'tracker_type' => 'medium', 'pet_type' => 'cat', 'count' => 1 },
                  { 'tracker_type' => 'medium', 'pet_type' => 'dog', 'count' => 0 },
                  { 'tracker_type' => 'big', 'pet_type' => 'dog', 'count' => 1 }], result)
  end

  test 'call with pet_type argument returns count of pets outside power saving zone grouped by pet_type' do
    params = { pet_type: 'dog' }

    result = CountPets.new(**params).call

    assert_equal([
                   { 'tracker_type' => 'small', 'pet_type' => 'dog', 'count' => 1 },
                   { 'tracker_type' => 'medium', 'pet_type' => 'dog', 'count' => 0 },
                   { 'tracker_type' => 'big', 'pet_type' => 'dog', 'count' => 1 }
                 ], result)
  end

  test 'call with tracker_type argument returns count of pets outside power saving zone grouped by tracker_type' do
    params = { tracker_type: 'small' }

    result = CountPets.new(**params).call

    assert_equal([
                   { 'tracker_type' => 'small', 'pet_type' => 'cat', 'count' => 0 },
                   { 'tracker_type' => 'small', 'pet_type' => 'dog', 'count' => 1 }
                 ], result)
  end

  test 'call with invalid pet_type argument raises error' do
    params = { pet_type: 'horse' }

    assert_raises(Dry::Types::ConstraintError) do
      CountPets.new(**params).call
    end
  end

  test 'call with invalid tracker_type argument raises error' do
    params = { tracker_type: 'very big' }

    assert_raises(Dry::Types::ConstraintError) do
      CountPets.new(**params).call
    end
  end
end
