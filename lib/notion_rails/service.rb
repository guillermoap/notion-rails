# frozen_string_literal: true

module NotionRails
  class Service
    def initialize
      @client = Notion::Client.new(token: NotionRails.config.notion_api_token)
    end

    def default_query(tag: nil, slug: nil)
      query = [
        {
          property: 'public',
          checkbox: {
            equals: true
          }
        }
      ]

      if slug
        query.push({
          property: 'slug',
          rich_text: {
            equals: slug
          }
        })
      end

      if tag
        query.push({
          property: 'tags',
          multi_select: {
            contains: tag
          }
        })
      end

      query
    end

    def default_sorting
      {
        property: 'published',
        direction: 'descending'
      }
    end

    def get_articles(tag: nil, slug: nil, page_size: 10)
      __get_articles(tag: tag, slug: slug, page_size: page_size)['results'].map do |page|
        NotionRails::BasePage.new(page)
      end
    end

    def get_article(id)
      base_page = NotionRails::BasePage.new(__get_article(id))
      base_blocks = NotionRails.config.cache_store.fetch(id) { get_blocks(id) }
      NotionRails::Page.new(base_page, base_blocks)
    end

    def get_blocks(id)
      blocks = __get_blocks(id)
      parent_list_block_index = nil
      results = []
      blocks['results'].each_with_index do |block, index|
        base_block = NotionRails::BaseBlock.new(block)
        base_block.children = get_blocks(base_block.id) if base_block.has_children
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

    private

    def __get_articles(tag: nil, slug: nil, page_size: 10)
      @client.database_query(
        database_id: NotionRails.config.database_id,
        sorts: [
          default_sorting
        ],
        filter: {
          'and': default_query(tag: tag, slug: slug)
        },
        page_size: page_size
      )
    end

    def __get_article(id)
      @client.page(page_id: id)
    end

    def __get_blocks(id)
      @client.block_children(block_id: id)
    end
  end
end
