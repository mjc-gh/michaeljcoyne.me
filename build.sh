#!/bin/bash
set -e

echo "================================"
echo "michaeljcoyne.me - Jekyll Build"
echo "================================"
echo ""

# Check if Gemfile exists
if [ ! -f "Gemfile" ]; then
  echo "Error: Gemfile not found. Are you in the project root?"
  exit 1
fi

echo "Step 1: Installing Ruby dependencies..."
bundle install

echo ""
echo "Step 2: Installing Node dependencies..."
npm install

echo ""
echo "Step 3: Compiling Tailwind CSS..."
npm run css

echo ""
echo "Step 4: Cleaning previous build..."
bundle exec jekyll clean

echo ""
echo "Step 5: Building Jekyll site..."
bundle exec jekyll build

echo ""
echo "================================"
echo "✓ Build complete!"
echo "================================"
echo ""
echo "Output directory: _site/"
echo ""
echo "To run development server:"
echo "  npm run watch & bundle exec jekyll serve"
echo ""
echo "Build output is ready for deployment."
