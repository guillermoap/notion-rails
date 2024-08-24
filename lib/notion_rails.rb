# frozen_string_literal: true

require 'active_support/all'
require 'notion_rails/renderers'
require 'notion_rails/base_block'
require 'notion_rails/base_page'
require 'notion_rails/page'
require 'notion_rails/service'
require 'dry-configurable'

module NotionRails
  extend Dry::Configurable

  setting :notion_api_token
  setting :notion_database_id
  setting :cache_store, default: ActiveSupport::Cache::MemoryStore.new
end
