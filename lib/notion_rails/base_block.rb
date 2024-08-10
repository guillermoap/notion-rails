# frozen_string_literal: true

module NotionRails
  class BaseBlock
    include NotionRails::Renderers

    # TODO: validate object type is block

    attr_reader :id,
      :created_time,
      :last_edited_time,
      :created_by,
      :last_edited_by,
      :parent,
      :archived,
      :has_children,
      :children,
      :siblings,
      :type,
      :properties

    attr_accessor :children, :siblings

    BLOCK_TYPES = %w[
      paragraph
      heading_1
      heading_2
      heading_3
      bulleted_list_item
      numbered_list_item
      quote
      callout
      code
      image
      video
      table_of_contents
    ].freeze

    def initialize(data)
      @id = data['id']
      @created_time = data['created_time']
      @last_edited_time = data['last_edited_time']
      # TODO: handle user object
      @created_by = data['created_by']
      @last_edited_by = data['last_edited_by']
      # TODO: handle page_id type
      @parent = data['parent']
      @archived = data['archived']
      @has_children = data['has_children']
      @children = []
      @siblings = []
      @type = data['type']
      @properties = data[@type]
    end

    def render(options = {})
      case @type
      when 'paragraph' then render_paragraph(rich_text, class: options[:paragraph])
      when 'heading_1' then render_heading_1(rich_text, class: options[:heading_1])
      when 'heading_2' then render_heading_2(rich_text, class: options[:heading_2])
      when 'heading_3' then render_heading_3(rich_text, class: options[:heading_3])
      when 'table_of_contents' then render_table_of_contents
      when 'bulleted_list_item'
        render_bulleted_list_item(rich_text, @siblings, @children, class: options[:bulleted_list_item])
      when 'numbered_list_item'
        render_numbered_list_item(rich_text, @siblings, @children, class: options[:numbered_list_item])
      when 'quote' then render_quote(rich_text, class: options[:quote])
      when 'callout' then render_callout(rich_text, icon, class: options[:callout])
      when 'code' then render_code(rich_text, class: "#{options[:code]} language-#{@properties["language"]}")
      when 'image' then render_image(*multi_media)
      when 'video' then render_video(*multi_media)
      else
        'Error'
      end
    end

    def rich_text
      @properties['rich_text'] || []
    end

    def icon
      icon = @properties['icon']
      @properties['icon'][icon['type']] || []
    end

    def multi_media
      case @properties['type']
      when 'file'
        [@properties.dig('file', 'url'), @properties.dig('file', 'expiry_time'), @properties['caption'], 'file']
      when 'external'
        [@properties.dig('external', 'url'), nil, @properties['caption'], 'external']
      else
        [nil, nil, @properties['caption'], nil]
      end
    end

    private

    def render_table_of_contents; end
  end
end
