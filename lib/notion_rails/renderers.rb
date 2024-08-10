# frozen_string_literal: true

require 'action_view'

module NotionRails
  module Renderers
    include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Context

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
          "text-#{annotations['color']}-600" if annotations[key] != 'default'
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
      end
    end

    def render_title(title, options = {})
      render_heading_1(title, options)
    end

    def render_date(date, options = {})
      # TODO: handle end and time zone
      # date=end=, start=2023-07-13, time_zone=, id=%5BsvU, type=date
      tag.p(date.to_date.to_fs(:long), class: options[:class])
    end

    def render_paragraph(rich_text_array, options = {})
      content_tag(:p, options) do
        text_renderer(rich_text_array).join('').html_safe
      end
    end

    def render_heading_1(rich_text_array, options = {})
      content_tag(:h1, class: 'mb-4 mt-6 text-3xl font-semibold', **options) do
        text_renderer(rich_text_array).join('').html_safe
      end
    end

    def render_heading_2(rich_text_array, options = {})
      content_tag(:h2, class: 'mb-4 mt-6 text-2xl font-semibold', **options) do
        text_renderer(rich_text_array).join('').html_safe
      end
    end

    def render_heading_3(rich_text_array, options = {})
      content_tag(:h3, class: 'mb-2 mt-6 text-xl font-semibold', **options) do
        text_renderer(rich_text_array).join('').html_safe
      end
    end

    def render_code(rich_text_array, options = {})
      # TODO: render captions
      pre_options = options
      pre_options[:class] = "border-2 p-6 rounded #{pre_options[:class]}"
      content_tag(:div, class: 'mt-4', data: { controller: 'highlight' }) do
        content_tag(:div, data: { highlight_target: 'source' }) do
          content_tag(:pre, pre_options) do
            text_renderer(rich_text_array, options).join('').html_safe
          end
        end
      end
    end

    def render_bulleted_list_item(rich_text_array, siblings, children, options = {})
      pre_options = options
      pre_options[:class] = "list-disc break-words #{pre_options[:class]}"
      content_tag(:ul, pre_options) do
        content = content_tag(:li, options) do
          text_renderer(rich_text_array).join('').html_safe
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

    def render_numbered_list_item(rich_text_array, siblings, children, options = {})
      pre_options = options
      pre_options[:class] = "list-decimal #{pre_options[:class]}"
      content_tag(:ol, pre_options) do
        render_list_items(:numbered_list_item, rich_text_array, siblings, children, options)
      end
    end

    def render_list_items(type, rich_text_array, siblings, children, options = {})
      content = content_tag(:li, options) do
        text_renderer(rich_text_array).join('').html_safe
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

    def render_quote(rich_text_array, options = {})
      div_options = options.dup
      pre_options = options.dup
      div_options[:class] = "mt-4 #{options[:class]}"
      content_tag(:div, div_options) do
        pre_options[:class] = "border-l-4 border-black px-5 py-1 #{options[:class]}"
        content_tag(:cite) do
          content_tag(:p, pre_options) do
            text_renderer(rich_text_array).join('').html_safe
          end
        end
      end
    end

    def render_callout(rich_text_array, icon, options = {})
      pre_options = options
      pre_options[:class] = "p-4 rounded bg-neutral-200 mt-4 #{pre_options[:class]}"
      content_tag(:div, pre_options) do
        content = tag.span(icon, class: 'pr-2')
        content += text_renderer(rich_text_array).join('').html_safe
        content
      end
    end

    def render_image(src, expiry_time, caption, type, options = {})
      content_tag(:figure, options) do
        content = tag.img(src:, alt: '')
        content += tag.figcaption(text_renderer(caption).join('').html_safe)
        content
      end
    end

    def render_video(src, expiry_time, caption, type, options = {})
      content_tag(:figure, options) do
        content = if type == 'file'
          video_tag(src, controls: true)
        elsif type == 'external'
          tag.iframe(src:, allowfullscreen: true, class: 'w-full aspect-video')
        end
        content += tag.figcaption(text_renderer(caption).join('').html_safe)
        content
      end
    end
  end
end

