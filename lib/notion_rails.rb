# frozen_string_literal: true

require 'notion_rails/renderers'
require 'notion_rails/base_block'
require 'notion_rails/base_page'
require 'notion_rails/page'
require 'notion_rails/service'
require 'dry-configurable'

module NotionRails
  extend Dry::Configurable

  setting :database_id
  setting :notion_api_token
end
