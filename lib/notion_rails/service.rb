module NotionRails
  class Service
    def initialize
      @client = Notion::Client.new
    end

    def get_articles(tag: nil, slug: nil)
      query = [
        {
          property: 'public',
          checkbox: {
            equals: true
          }
        },
        {
          property: 'slug',
          rich_text: {
            is_not_empty: true
          }
        }
      ]

      query.push({
        property: 'slug',
        rich_text: {
          equals: slug,
        }
      }) if slug

      query.push({
        property: 'tags',
        multi_select: {
          contains: tag,
        }
      }) if tag

      pages = @client.database_query(
        database_id: Rails.application.credentials.notion.database_id,
        sorts: [
          {
            property: 'published',
            direction: 'descending'
          }
        ],
        filter: {
          'and': query
        }
      )
      pages['results'].map { |page| Notion::BasePage.new(page) }
    end

    def get_article(id)
      base_page = Notion::BasePage.new(@client.page(page_id: id))
      base_blocks = get_blocks(id)
      Notion::Page.new(base_page, base_blocks)
    end

    def get_blocks(id)
      blocks = @client.block_children(block_id: id)
      parent_list_block_index = nil
      results = []
      blocks['results'].each_with_index do |block, index|
        base_block = Notion::BaseBlock.new(block)
        if base_block.has_children
          base_block.children = get_blocks(base_block.id)
        end
        # Notion returns same list items as different blocks so we have to do some processing to have them be related
        # TODO: Separate this into a function, add support for bulleted items.
        #       Currently bulleted items render fine, but they do it in separate ul blocks
        #       Make them appear in the same ul block as numbered_items appear in the same ol block
        if %w[numbered_list_item].include? base_block.type
          siblings = !parent_list_block_index.nil? &&
                      index != parent_list_block_index &&
                      base_block.type == results[parent_list_block_index]&.type &&
                      base_block.parent == results[parent_list_block_index]&.parent
          if siblings
            results[parent_list_block_index].siblings << base_block
            next
          else
            parent_list_block_index = results.length
          end
        else
          parent_list_block_index = nil
        end
        results << base_block
      end
      results
    end
  end
end
