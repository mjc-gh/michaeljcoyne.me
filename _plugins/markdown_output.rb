# frozen_string_literal: true

# Write raw markdown to output directory
Jekyll::Hooks.register :posts, :post_write do |post|
  output_file = File.join(post.site.dest, "posts", File.basename(post.path))

  File.open(post.path) do |markdown|
    File.open(output_file, "w+") do |output|
      output << markdown.read
    end
  end
end
