# frozen_String_literal: true

require 'test_helper'

class CreatePetTest < ActiveSupport::TestCase
  test 'call with valid arguments returs true' do
    data = { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true, lost_tracker: false }

    result = CreatePet.new(**data).call

    assert_equal(true, result)
  end

  test 'call with valid arguments creates pet tracking data' do
    data = { pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true, lost_tracker: false }
    pets_data = Kredis.hash 'pets_data'

    CreatePet.new(**data).call

    assert(pets_data['1_cat_small'])
    assert_equal(
      [{ pet_type: 'cat', tracker_type: 'small', owner_id: 1, in_zone: true,
         lost_tracker: false }.transform_keys(&:to_s)], JSON.parse(pets_data['1_cat_small'])
    )
  end

  test 'call with in_zone as false should update grouped count of traked data' do
    data = { pet_type: 'dog', tracker_type: 'small', owner_id: 1, in_zone: false }
    grouped_data = Kredis.list 'grouped_data'

    CreatePet.new(**data).call
    assert_equal(['{"tracker_type":"small","pet_type":"dog","count":1}'], grouped_data.elements)
  end

  test 'call with invalid pet_type argument raises error' do
    data = { pet_type: 'horse', tracker_type: 'small', owner_id: 1, in_zone: false }

    assert_raises(Dry::Types::ConstraintError) do
      CreatePet.new(**data).call
    end
  end

  test 'call with invalid tracker_type argument raises error' do
    data = { pet_type: 'horse', tracker_type: 'small', owner_id: 1, in_zone: false }

    assert_raises(Dry::Types::ConstraintError) do
      CreatePet.new(**data).call
    end
  end

  test 'call without required argument raises error' do
    data = { pet_type: 'dog', owner_id: 1, in_zone: false }

    assert_raises(KeyError) do
      CreatePet.new(**data).call
    end
  end
end
