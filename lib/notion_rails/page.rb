# frozen_string_literal: true

module Notion
  class Page
    include Notion::Renderers

    attr_reader :metadata, :blocks

    delegate :formatted_title, to: :metadata
    delegate :formatted_description, to: :metadata
    delegate :formatted_published_at, to: :metadata

    def initialize(base_page, base_blocks)
      @metadata = base_page
      @blocks = base_blocks
    end

    def formatted_blocks(options = {})
      @blocks.map { |block| block.render(options) }
    end
  end
end
