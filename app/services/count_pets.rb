# frozen_string_literal: true

# This handled querying/searching to fetch count of pets outside power saving zone from the `grouped_data` list
# which is grouped by `pet_type` and `tracker_type`. This takes 2 optional arguments to fetch specific group count.
class CountPets < BaseService
  include Kredis::Attributes
  extend Dry::Initializer

  kredis_list :grouped_data, key: 'grouped_data', typed: :json

  # Optional arguments to enable API to filter grouped count information according to filters sent in params.
  option :pet_type, Types::String.enum('cat', 'dog'), optional: true
  option :tracker_type, Types::String.enum('small', 'medium', 'big'), optional: true

  def call
    filtered_grouped_data = grouped_data.elements

    filtered_grouped_data = filtered_grouped_data.select { |c| c['pet_type'] == pet_type } if pet_type.present?

    filtered_grouped_data = filtered_grouped_data.select { |c| c['tracker_type'] == tracker_type } if tracker_type.present?

    filtered_grouped_data
  end
end
