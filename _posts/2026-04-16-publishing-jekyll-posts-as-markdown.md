# Publishing Jekyll Posts as Markdown

In the era of agentic development and workflows, plaintext and Markdown content has quickly become the de facto way of capturing and sharing context for LLM sessions.

Leaning into this trend, I've added a small Jekyll plugin to my site that will publish the original markdown content when the site is built. Simply replace the .html at the end of a post's URL with .md and you will be able to get the content in markdown format.

Adding support was easy. First, I created a plugin under `_plugins/markdown_output.rb` with the following hook:

```ruby
# Write raw markdown to output directory
Jekyll::Hooks.register :posts, :post_write do |post|
  output_file = File.join(post.site.dest, "posts", File.basename(post.path))

  File.open(post.path) do |markdown|
    File.open(output_file, "w+") do |output|
      output << markdown.read
    end
  end
end
```

Next, I create a small Liquid filter in `_plugins/markdown_output.rb` to transform the page's HTML URL into an `.md` URL:

```ruby
module Jekyll
  module MarkdownLinkFilter
    def to_markdown_link(input)
      input.gsub(/\.html\z/, ".md")
    end
  end
end

Liquid::Template.register_filter(Jekyll::MarkdownLinkFilter)
```

In my `_layouts/post.html`, I then added a link to view the post as Markdown with the following HTML:

```html
<a href="{{ page.url | to_markdown_link }}">
  View as Markdown
</a>
```
How easy is that? All the posts on this site will have a link below the post header to view the content as Markdown.
