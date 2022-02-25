require 'extensions/photo_resize'

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.txt', layout: false

# General configuration
set :fonts_dir,  'fonts'

# Enable middleman-protect-emails
activate :protect_emails

# Enable robot friendly site maps
activate :sitemap, hostname: 'https://www.michaeljcoyne.me'

# Setup and activate photo resize extension
PHOTO_SIZES = {
  small:  960,
  medium: 1920,
  large:  2800
}

ignore 'photos/*'
ignore 'photography.html'
ignore 'open-source.html'

activate :photo_resize,
  path_name: 'photos', sizes: PHOTO_SIZES

###
# Helpers

helpers do
end

# Build-specific configuration
configure :build do
  config[:host] = "https://www.michaeljcoyne.me"

  # Minify CSS on build
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript
end

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end
