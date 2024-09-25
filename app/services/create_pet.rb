# frozen_string_literal: true

# This handles validating the pet info attributes and its type, It is also responsible for storing the pet tracking
# information. This also handles the logic to update count of pets outside the zone grouped by pet_type and tracker_type.
class CreatePet < BaseService
  include Kredis::Attributes
  extend Dry::Initializer

  kredis_list :pets_data, key: 'pets_data', typed: :json
  kredis_list :grouped_data, key: 'grouped_data', typed: :json

  # Mandatory attributes to create Pet(Dog and Cat) entity.
  option :pet_type, Types::String.enum('cat', 'dog')
  option :tracker_type, Types::String.enum('small', 'medium', 'big')
  option :owner_id, Types::Strict::Integer, type: proc(&:to_i)
  option :in_zone, Types::Strict::Bool

  # Optional attribute to create Cat entity.
  option :lost_tracker, Types::Strict::Bool, optional: true

  # Default attributes to find last pet tracking info of the owner and also
  # to find specific pet count info grouped by provided tracker_type and pet_type.
  option :last_pet_tracked_info, default:
          proc { pets_data.elements.select { |pd| pd['owner_id'] == @owner_id && pd['pet_type'] == @pet_type }.last }
  option :pet_tracker_group, default:
          proc { grouped_data.elements.find { |gd| gd['tracker_type'] == @tracker_type && gd['pet_type'] == @pet_type } }

  def call
    update_owners_pet_data
    init_grouped_data
    update_grouped_data
  end

  # This method pushed received data from trackers to pet_data list.
  # It also adds extra info of `lost_tracker` attribute for cat.
  def update_owners_pet_data
    if pet_type == 'cat'
      pets_data.append({ pet_type: pet_type, tracker_type: tracker_type, owner_id: owner_id, in_zone: in_zone,
                         lost_tracker: lost_tracker })

    else
      pets_data.append({ pet_type: pet_type, tracker_type: tracker_type, owner_id: owner_id, in_zone: in_zone })
    end
  end

  # This method updates the `grouped_data` list which stores the count of pets which are outside power saving zone.
  # We remove the old value of specific group data and replace it with new count. We also increment and decrement the
  # count of specific group by comparing it with the last tracked info of the pet.
  def update_grouped_data
    return unless pet_tracker_group.present?
    return unless last_pet_tracked_info.present?

    if last_pet_tracked_info['in_zone'] == true && in_zone == false
      grouped_data.remove(tracker_group)
      grouped_data.append({ tracker_type: tracker_type, pet_type: pet_type, count: tracker_group['count'] + 1 })
    elsif last_pet_tracked_info['in_zone'] == false && in_zone == true
      grouped_data.remove(tracker_group)
      grouped_data.append({ tracker_type: tracker_type, pet_type: pet_type, count: tracker_group['count'] - 1 })
    end
  end

  # This method initializes specific group with its count of pets outside power saving zone
  # when we first receives the data from the tracker. Once we it is created and its count is
  # being updated by `update_grouped_data` method.

  # We also initialize count with 0 or 1 according the first `in_zone` value we get from the tracker.
  def init_grouped_data
    return if pet_tracker_group.present?

    count = in_zone ? 0 : 1
    grouped_data.append({ tracker_type: tracker_type, pet_type: pet_type, count: count })
  end
end
