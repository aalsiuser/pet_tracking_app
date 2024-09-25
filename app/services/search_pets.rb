# frozen_string_literal: true

# This handles querying/searching of pets according owner_id, pet_type, tracker_type, in_zone and lost_tracker attrs.
# This uses same redis key `pets_data` list which stores all the pet information to filter/search for the tracking info.
class SearchPets < BaseService
  include Kredis::Attributes
  extend Dry::Initializer

  kredis_hash :pets_data, key: 'pets_data'

  # Optional arguments to enable API to filter tracking information according to filters sent in params.
  option :id, Types::Strict::String, type: proc(&:to_i), optional: true
  option :pet_type, Types::String.enum('cat', 'dog'), optional: true
  option :tracker_type, Types::String.enum('small', 'medium', 'big'), optional: true

  def call
    key = "#{id || '.*'}_#{pet_type || '.*'}_#{tracker_type || '.*'}"

    keys = pets_data.to_h.keys.grep(/#{key}/)

    keys.map { |k| JSON.parse(pets_data[k]) }.flatten
  end
end
