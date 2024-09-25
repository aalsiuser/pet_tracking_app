# frozen_string_literal: true

# This handles querying/searching of pets according owner_id, pet_type, tracker_type, in_zone and lost_tracker attrs.
# This uses same redis key `pets_data` list which stores all the pet information to filter/search for the tracking info.
class SearchPets < BaseService
  include Kredis::Attributes
  extend Dry::Initializer

  kredis_list :pets_data, key: 'pets_data', typed: :json

  # Optional arguments to enable API to filter tracking information according to filters sent in params.
  option :id, Types::Strict::String, type: proc(&:to_i), optional: true
  option :pet_type, Types::String.enum('cat', 'dog'), optional: true
  option :tracker_type, Types::String.enum('small', 'medium', 'big'), optional: true
  option :in_zone, Types::Strict::Bool, optional: true
  option :lost_tracker, Types::Strict::Bool, optional: true

  def call
    filtered_pets_data = pets_data.elements

    filtered_pets_data = filtered_pets_data.select { |pd| pd['owner_id'] == id }

    filtered_pets_data = filtered_pets_data.select { |c| c['pet_type'] == pet_type } if pet_type.present?

    filtered_pets_data = filtered_pets_data.select { |c| c['tracker_type'] == tracker_type } if tracker_type.present?

    filtered_pets_data = filtered_pets_data.select { |c| c['tracker_type'] == in_zone } if in_zone.present?

    filtered_pets_data = filtered_pets_data.select { |c| c['tracker_type'] == lost_tracker } if lost_tracker.present?

    filtered_pets_data
  end
end
