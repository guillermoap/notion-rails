# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotionRails::Renderers do
  include NotionRails::Renderers

  describe '#annotation_to_css_class' do
    context 'when annotations are default' do
      let(:annotations) do
        { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
          'color' => 'default' }
      end

      it 'returns an empty string' do
        expect(annotation_to_css_class(annotations)).to eq('')
      end
    end

    context 'when annotations include bold' do
      let(:annotations) do
        { 'bold' => true, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
          'color' => 'default' }
      end

      it 'returns the font-bold class' do
        expect(annotation_to_css_class(annotations)).to eq('font-bold')
      end
    end

    context 'when annotations include italic' do
      let(:annotations) do
        { 'bold' => false, 'italic' => true, 'strikethrough' => false, 'underline' => false, 'code' => false,
          'color' => 'default' }
      end

      it 'returns the italic class' do
        expect(annotation_to_css_class(annotations)).to eq('italic')
      end
    end

    context 'when annotations include underline' do
      let(:annotations) do
        { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => true, 'code' => false,
          'color' => 'default' }
      end

      it 'returns the underline class' do
        expect(annotation_to_css_class(annotations)).to eq('underline')
      end
    end

    context 'when annotations include color' do
      let(:annotations) do
        { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
          'color' => 'red' }
      end

      it 'returns the color class' do
        expect(annotation_to_css_class(annotations)).to eq('text-red-600')
      end
    end

    context 'when annotations include multiple styles' do
      let(:annotations) do
        { 'bold' => true, 'italic' => true, 'strikethrough' => true, 'underline' => true, 'code' => true,
          'color' => 'blue' }
      end

      it 'returns the combined class names' do
        expect(annotation_to_css_class(annotations)).to eq('font-bold italic line-through underline inline-code text-blue-600')
      end
    end
  end

  describe '#text_renderer' do
    context 'when rich text has no annotations' do
      let(:rich_text) do
        [{ 'plain_text' => 'Hello, world!',
           'annotations' => { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
                              'color' => 'default' } }]
      end

      it 'renders plain text without additional classes' do
        html = text_renderer(rich_text)
        rendered_html = Capybara.string(html)

        expect(rendered_html).to have_selector('span', text: 'Hello, world!')
        expect(rendered_html).not_to have_selector('span.font-bold')
      end
    end

    context 'when rich text has bold annotation' do
      let(:rich_text) do
        [{ 'plain_text' => 'Bold text',
           'annotations' => { 'bold' => true, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
                              'color' => 'default' } }]
      end

      it 'renders text with bold class' do
        html = text_renderer(rich_text)
        rendered_html = Capybara.string(html)

        expect(rendered_html).to have_selector('span.font-bold', text: 'Bold text')
      end
    end

    context 'when rich text has color annotation' do
      let(:rich_text) do
        [{ 'plain_text' => 'Colored text',
           'annotations' => { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
                              'color' => 'green' } }]
      end

      it 'renders text with color class' do
        html = text_renderer(rich_text)
        rendered_html = Capybara.string(html)

        expect(rendered_html).to have_selector('span.text-green-600', text: 'Colored text')
      end
    end

    context 'when rich text includes a hyperlink' do
      let(:rich_text) do
        [{ 'plain_text' => 'Link text',
           'annotations' => { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false, 'color' => 'default' }, 'href' => 'https://example.com' }]
      end

      it 'renders a link with the correct href' do
        html = text_renderer(rich_text)
        rendered_html = Capybara.string(html)

        expect(rendered_html).to have_selector('a[href="https://example.com"]', text: 'Link text')
      end
    end
  end

  describe '#render_paragraph' do
    it 'renders a paragraph with rich text' do
      rich_text = [{ 'plain_text' => 'Hello, world!', 'annotations' => { 'bold' => true } }]
      html = render_paragraph(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('p')
      expect(rendered_html).to have_selector('span.font-bold', text: 'Hello, world!')
    end

    it 'adds custom CSS class to the paragraph' do
      rich_text = [{ 'plain_text' => 'Hello, world!', 'annotations' => { 'bold' => true } }]
      html = render_paragraph(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('p.custom-class')
    end
  end

  describe '#render_image' do
    it 'renders an image with a caption' do
      caption = [{ 'plain_text' => 'An image caption', 'annotations' => {} }]
      html = render_image('image_src.jpg', nil, caption, 'file')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('figure')
      expect(rendered_html).to have_selector('img[src="image_src.jpg"]')
      expect(rendered_html).to have_selector('figcaption', text: 'An image caption')
    end

    it 'adds custom CSS class to the image' do
      caption = [{ 'plain_text' => 'An image caption', 'annotations' => {} }]
      html = render_image('image_src.jpg', nil, caption, 'file', class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('figure.custom-class')
    end
  end

  describe '#render_video' do
    it 'renders a video with a caption' do
      caption = [{ 'plain_text' => 'A video caption', 'annotations' => {} }]
      html = render_video('video_src.mp4', nil, caption, 'file')

      rendered_html = Capybara.string(html)
      expect(rendered_html).to have_selector('figure')
      expect(rendered_html).to have_selector('figcaption', text: 'A video caption')
      video_element = rendered_html.find('video')
      expect(video_element[:src]).to match(/video_src.mp4/)
      expect(video_element[:controls]).to eq('controls')
    end

    it 'adds custom CSS class to the video' do
      caption = [{ 'plain_text' => 'A video caption', 'annotations' => {} }]
      html = render_video('video_src.mp4', nil, caption, 'file', class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('figure.custom-class')
    end
  end

  describe '#render_heading_1' do
    it 'renders a heading 1 with rich text' do
      rich_text = [{ 'plain_text' => 'Heading 1', 'annotations' => { 'bold' => true } }]
      html = render_heading_1(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h1.text-3xl.font-semibold', text: 'Heading 1')
    end

    it 'adds custom CSS class to the heading 1' do
      rich_text = [{ 'plain_text' => 'Heading 1', 'annotations' => { 'bold' => true } }]
      html = render_heading_1(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h1.custom-class', text: 'Heading 1')
    end
  end

  describe '#render_heading_2' do
    it 'renders a heading 2 with rich text' do
      rich_text = [{ 'plain_text' => 'Heading 2', 'annotations' => { 'italic' => true } }]
      html = render_heading_2(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h2.text-2xl.font-semibold', text: 'Heading 2')
    end

    it 'adds custom CSS class to the heading 2' do
      rich_text = [{ 'plain_text' => 'Heading 2', 'annotations' => { 'italic' => true } }]
      html = render_heading_2(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h2.custom-class', text: 'Heading 2')
    end
  end

  describe '#render_heading_3' do
    it 'renders a heading 3 with rich text' do
      rich_text = [{ 'plain_text' => 'Heading 3', 'annotations' => { 'underline' => true } }]
      html = render_heading_3(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h3.text-xl.font-semibold', text: 'Heading 3')
    end

    it 'adds custom CSS class to the heading 3' do
      rich_text = [{ 'plain_text' => 'Heading 3', 'annotations' => { 'underline' => true } }]
      html = render_heading_3(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h3.custom-class', text: 'Heading 3')
    end
  end

  describe '#render_code' do
    it 'renders a code block with rich text' do
      rich_text = [{ 'plain_text' => 'puts "Hello, world!"', 'annotations' => { 'code' => true } }]
      html = render_code(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('pre.border-2.p-6.rounded', text: 'puts "Hello, world!"')
    end

    it 'adds custom CSS class to the code block' do
      rich_text = [{ 'plain_text' => 'puts "Hello, world!"', 'annotations' => { 'code' => true } }]
      html = render_code(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('pre.custom-class', text: 'puts "Hello, world!"')
    end
  end

  describe '#render_bulleted_list_item' do
    it 'renders a bulleted list item with rich text' do
      rich_text = [{ 'plain_text' => 'List item', 'annotations' => {} }]
      html = render_bulleted_list_item(rich_text, [], [])

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('ul.list-disc.break-words li', text: 'List item')
    end

    it 'adds custom CSS class to the bulleted list item' do
      rich_text = [{ 'plain_text' => 'List item', 'annotations' => {} }]
      html = render_bulleted_list_item(rich_text, [], [], class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('ul.list-disc.break-words li.custom-class', text: 'List item')
    end
  end

  describe '#render_numbered_list_item' do
    it 'renders a numbered list item with rich text' do
      rich_text = [{ 'plain_text' => 'List item', 'annotations' => {} }]
      html = render_numbered_list_item(rich_text, [], [])

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('ol.list-decimal li', text: 'List item')
    end

    it 'adds custom CSS class to the numbered list item' do
      rich_text = [{ 'plain_text' => 'List item', 'annotations' => {} }]
      html = render_numbered_list_item(rich_text, [], [], class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('ol.list-decimal li.custom-class', text: 'List item')
    end
  end

  describe '#render_quote' do
    it 'renders a quote with rich text' do
      rich_text = [{ 'plain_text' => 'A quote', 'annotations' => {} }]
      html = render_quote(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('cite p.border-l-4.border-black.px-5.py-1', text: 'A quote')
    end

    it 'adds custom CSS classes when options with class key are passed' do
      rich_text = [{ 'plain_text' => 'A styled quote', 'annotations' => {} }]
      options = { class: 'custom-quote-class' }
      html = render_quote(rich_text, options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('cite p.custom-quote-class', text: 'A styled quote')
    end
  end

  describe '#render_callout' do
    it 'renders a callout with rich text and icon' do
      rich_text = [{ 'plain_text' => 'A callout', 'annotations' => {} }]
      html = render_callout(rich_text, '⚠️')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('div.p-4.rounded.bg-neutral-200.mt-4', text: 'A callout')
      expect(rendered_html).to have_selector('span', text: '⚠️')
    end

    it 'adds custom CSS classes when options with class key are passed' do
      rich_text = [{ 'plain_text' => 'A styled callout', 'annotations' => {} }]
      options = { class: 'custom-callout-class' }
      html = render_callout(rich_text, '⚠️', options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('div.custom-callout-class', text: 'A styled callout')
    end
  end

  describe '#render_title' do
    it 'renders a title as heading 1' do
      rich_text = [{ 'plain_text' => 'Title', 'annotations' => { 'bold' => true } }]
      html = render_title(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h1.text-3xl.font-semibold', text: 'Title')
    end

    it 'adds custom CSS classes when options with class key are passed' do
      rich_text = [{ 'plain_text' => 'Styled Title', 'annotations' => { 'bold' => true } }]
      options = { class: 'custom-title-class' }
      html = render_title(rich_text, options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h1.custom-title-class', text: 'Styled Title')
    end
  end

  describe '#render_date' do
    it 'renders a date' do
      date = Date.new(2023, 7, 13)
      html = render_date(date)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('p', text: 'July 13, 2023')
    end

    it 'adds custom CSS classes when options with class key are passed' do
      date = Date.new(2023, 7, 13)
      options = { class: 'custom-date-class' }
      html = render_date(date, options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('p.custom-date-class', text: 'July 13, 2023')
    end
  end
end
