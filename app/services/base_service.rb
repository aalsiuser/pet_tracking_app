# frozen_string_literal: true

require 'dry-initializer'
require 'dry-types'
require 'dry-struct'

# Module to include types from `dry-types` to validate arguments data type sent in service classes.
module Types
  include Dry.Types()
end

# This is the basic/general skeleton which other services classes for redundant importin of `dry` modules.
class BaseService; end
