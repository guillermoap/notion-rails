# frozen_string_literal: true

require 'notion_rails/version'
require 'notion_rails/service'
require 'dry-configurable'

module NotionRails
  extend Dry::Configurable

  setting :database_id
end
