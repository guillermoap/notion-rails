module NotionRails
  class Page
    include NotionRails::Renderers

    attr_reader :metadata, :blocks

    delegate :formatted_title, to: :metadata

    def initialize(base_page, base_blocks)
	  	@metadata = base_page
		  @blocks = base_blocks
  	end

		def formatted_blocks(options = {})
			@blocks.map { |block| block.render(options) }
		end
  end
end
