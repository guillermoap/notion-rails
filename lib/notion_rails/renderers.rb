# frozen_string_literal: true

require 'action_view'

module NotionRails
  module Renderers
    include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Context

    DEFAULT_CSS_CLASSES = {
      bulleted_list_item: 'list-disc break-words',
      callout: 'flex flex-column p-4 rounded mt-4',
      code: 'border-2 p-6 rounded w-full overflow-x-auto',
      heading_1: 'mb-4 mt-6 text-3xl font-semibold',
      heading_2: 'mb-4 mt-6 text-2xl font-semibold',
      heading_3: 'mb-2 mt-6 text-xl font-semibold',
      image: '',
      numbered_list_item: 'list-decimal',
      paragraph: '',
      quote: 'border-l-4 border-black px-5 py-1',
      table_of_contents: '',
      video: ''
    }.freeze

    def annotation_to_css_class(annotations)
      classes = annotations.keys.map do |key|
        case key
        when 'strikethrough'
          'line-through' if annotations[key]
        when 'bold'
          'font-bold' if annotations[key]
        when 'code'
          'inline-code' if annotations[key]
        when 'color'
          "text-#{annotations["color"]}-600" if annotations[key] != 'default'
        else
          annotations[key] ? key : nil
        end
      end
      classes.compact.join(' ')
    end

    def text_renderer(properties, options = {})
      properties.map do |rich_text|
        classes = annotation_to_css_class(rich_text['annotations'])
        if rich_text['href']
          link_to(
            rich_text['plain_text'],
            rich_text['href'],
            class: "link #{classes} #{options[:class]}"
          )
        elsif classes.present?
          content_tag(:span, rich_text['plain_text'], class: "#{classes} #{options[:class]}")
        else
          tag.span(rich_text['plain_text'], class: options[:class])
        end
      end.join('').html_safe
    end

    def render_bulleted_list_item(rich_text_array, _siblings, children, options = {})
      content_tag(:ul, **options, class: css_class_for(:bulleted_list_item, options)) do
        content = content_tag(:li, options) do
          text_renderer(rich_text_array)
        end
        if children.present?
          res = children.map do |child|
            render_bulleted_list_item(child.rich_text, child.siblings, child.children, options)
          end
          content += res.join('').html_safe
        end
        content.html_safe
      end
    end

    def render_callout(rich_text_array, icon, options = {})
      content_tag(:div, **options, class: css_class_for(:callout, options)) do
        content = tag.span(icon, class: 'mr-4')
        content += tag.div do
          text_renderer(rich_text_array)
        end
        content
      end
    end

    def render_code(rich_text_array, options = {})
      # TODO: render captions
      content_tag(:div, data: { controller: 'highlight' }) do
        content_tag(:div, data: { highlight_target: 'source' }) do
          content_tag(:pre, **options, class: "#{css_class_for(:code, options)} language-#{options[:language]}") do
            text_renderer(rich_text_array, options)
          end
        end
      end
    end

    def render_date(date, options = {})
      # TODO: handle end and time zone
      # date=end=, start=2023-07-13, time_zone=, id=%5BsvU, type=date
      tag.p(date.to_date.to_fs(:long), class: css_class_for(:date, options))
    end

    def render_heading_1(rich_text_array, options = {})
      content_tag(:h1, **options, class: css_class_for(:heading_1, options)) do
        text_renderer(rich_text_array)
      end
    end

    def render_heading_2(rich_text_array, options = {})
      content_tag(:h2, **options, class: css_class_for(:heading_2, options)) do
        text_renderer(rich_text_array)
      end
    end

    def render_heading_3(rich_text_array, options = {})
      content_tag(:h3, **options, class: css_class_for(:heading_3, options)) do
        text_renderer(rich_text_array)
      end
    end

    def render_image(src, _expiry_time, caption, _type, options = {})
      content_tag(:figure, **options, class: css_class_for(:image, options)) do
        content = tag.img(src: src, alt: '')
        content += tag.figcaption(text_renderer(caption))
        content
      end
    end

    def render_numbered_list_item(rich_text_array, siblings, children, options = {})
      content_tag(:ol, **options, class: css_class_for(:numbered_list_item, options)) do
        render_list_items(:numbered_list_item, rich_text_array, siblings, children, options)
      end
    end

    def render_paragraph(rich_text_array, options = {})
      content_tag(:p, **options, class: css_class_for(:paragraph, options)) do
        text_renderer(rich_text_array)
      end
    end

    def render_quote(rich_text_array, options = {})
      content_tag(:div, options) do
        content_tag(:cite) do
          content_tag(:p, **options, class: css_class_for(:quote, options)) do
            text_renderer(rich_text_array)
          end
        end
      end
    end

    def render_title(title, options = {})
      render_heading_1(title, options)
    end

    def render_video(src, _expiry_time, caption, type, options = {})
      content_tag(:figure, options) do
        content = if type == 'file'
                    video_tag(src, controls: true, **options, class: css_class_for(:video, options))
                  elsif type == 'external'
                    tag.iframe(src: src, allowfullscreen: true, **options, class: css_class_for(:video, options))
                  end
        content += tag.figcaption(text_renderer(caption))
        content
      end
    end

    private

    def css_class_for(type, options)
      if options[:override]
        options[:class]
      else
        "#{DEFAULT_CSS_CLASSES[type]} #{options[:class]}".lstrip
      end
    end

    def render_list_items(type, rich_text_array, siblings, children, options = {})
      content = content_tag(:li, options) do
        text_renderer(rich_text_array)
      end
      if children.present?
        res = children.map do |child|
          render_numbered_list_item(child.rich_text, child.siblings, child.children)
        end
        content += res.join('').html_safe
      end
      if siblings.present?
        content += siblings.map do |sibling|
          render_list_items(type, sibling.rich_text, sibling.siblings, sibling.children, options)
        end.join('').html_safe
      end
      content.html_safe
    end
  end
end
