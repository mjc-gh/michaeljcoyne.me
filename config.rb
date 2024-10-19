# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

config[:target] = ENV.fetch('TARGET') { 'development' }
config[:host] = case config[:target]
                when 'development' then 'http://localhost:4567/'
                else 'https://michaeljcoyne.me/'
                end

activate :tailwind do |tailwind|
  tailwind.config_path = "tailwind.config.js"
end

activate :autoprefixer do |prefix|
  prefix.browsers = "last 2 versions"
end

configure :build do
  activate :asset_hash, ignore: [
    /og-image\.png/
  ]
end

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

helpers do
  def site_title
    "michaeljcoyne.me"
  end

  def site_description
    "Hello, I'm Michael! I am a computing scientist, software engineer, and tech start-up advisor living in NYC."
  end

  def well_tag(&block)
    content_tag :div, class: "bg-slate-900 text-white rounded-md border border-slate-600 p-8 relative", &block
  end
end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

# configure :build do
#   activate :minify_css
#   activate :minify_javascript, compressor: Terser.new
# end
