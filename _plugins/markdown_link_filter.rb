# frozen_string_literal: true

module Jekyll
  module MarkdownLinkFilter
    def to_markdown_link(input)
      input.gsub(/\.html\z/, ".md")
    end
  end
end

Liquid::Template.register_filter(Jekyll::MarkdownLinkFilter)
