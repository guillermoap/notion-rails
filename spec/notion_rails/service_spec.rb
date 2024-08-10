# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotionRails::Service do
  let(:service) { described_class.new }

  describe '#initialize' do
    it 'initializes a Notion::Client' do
      client = service.instance_variable_get(:@client)
      expect(client).to be_a(Notion::Client)
    end
  end

  describe '#default_query' do
    context 'when no slug or tag is provided' do
      it 'returns the default query' do
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          }
        ]
        expect(service.default_query).to eq(expected_query)
      end
    end

    context 'when a slug is provided' do
      it 'includes the slug in the query' do
        slug = 'example-slug'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'slug',
            rich_text: { equals: slug }
          }
        ]
        expect(service.default_query(slug: slug)).to eq(expected_query)
      end
    end

    context 'when a tag is provided' do
      it 'includes the tag in the query' do
        tag = 'example-tag'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'tags',
            multi_select: { contains: tag }
          }
        ]
        expect(service.default_query(tag: tag)).to eq(expected_query)
      end
    end

    context 'when both slug and tag are provided' do
      it 'includes both the slug and tag in the query' do
        slug = 'example-slug'
        tag = 'example-tag'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'slug',
            rich_text: { equals: slug }
          },
          {
            property: 'tags',
            multi_select: { contains: tag }
          }
        ]
        expect(service.default_query(slug: slug, tag: tag)).to eq(expected_query)
      end
    end
  end

  describe '#default_sorting' do
    it 'returns the default sorting hash' do
      expected_sorting = { property: 'published', direction: 'descending' }
      expect(service.default_sorting).to eq(expected_sorting)
    end
  end

  describe '#get_articles' do
    subject { service.get_articles(tag: 'test', page_size: page_size) }

    let(:page_size) { 10 }

    it 'queries the Notion database and returns articles', vcr: { cassette_name: 'get_articles' } do
      expect(subject).to be_an(Array)
      expect(subject.first).to be_a(NotionRails::BasePage)
    end
  end

  describe '#get_article' do
    subject { service.get_article(id) }

    let(:id) { service.get_articles(tag: 'test', page_size: 10).first.id }

    it 'returns a NotionRails::Page with the correct base_page and base_blocks',
      vcr: { cassette_name: 'get_article' } do
      expect(subject).to be_a(NotionRails::Page)
      expect(subject.metadata).to be_a(NotionRails::BasePage)
      expect(subject.blocks).to be_an(Array)
    end
  end

  describe '#get_blocks' do
    subject { service.get_blocks(id) }

    let(:id) { service.get_articles(tag: 'test', page_size: 10).first.id }

    it 'returns an array of blocks', vcr: { cassette_name: 'get_blocks' } do
      expect(subject).to be_an(Array)
      expect(subject.first).to be_a(NotionRails::BaseBlock)
    end
  end
end
