# frozen_string_literal: true

require 'test_helper'

class SearchPetsTest < ActiveSupport::TestCase
  def setup
    data = [
      { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true, lost_tracker: false },
      { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: true },
      { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: false, lost_tracker: false },
      { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: true }
    ]

    data.each { |param| CreatePet.new(**param).call }
  end

  test 'call with id argument returns owners pet data' do
    params = { id: 1 }

    result = SearchPets.new(**params).call

    assert_equal(4, result.size)
  end

  test 'call pet_type argument return pets data filtered by pet_type' do
    params = { pet_type: 'dog' }

    result = SearchPets.new(**params).call

    assert_equal(2, result.size)
    assert_equal(['dog'], result.pluck('pet_type').uniq)
  end

  test 'call tracker_type argument return pets data filtered by tracker_type' do
    params = { tracker_type: 'small' }

    result = SearchPets.new(**params).call

    assert_equal(4, result.size)
    assert_equal(['small'], result.pluck('tracker_type').uniq)
  end

  test 'call with invalid pet_type argument raises error' do
    params = { id: 1, pet_type: 'horse' }

    assert_raises(Dry::Types::ConstraintError) do
      SearchPets.new(**params).call
    end
  end

  test 'call with invalid tracker_type argument raises error' do
    params = { id: 1, tracker_type: 'very big' }

    assert_raises(Dry::Types::ConstraintError) do
      SearchPets.new(**params).call
    end
  end
end
