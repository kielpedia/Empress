#!/usr/bin/env ruby

# Copyright (c) 2013 Matt Hodges (http://matthodges.com)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rubygems'
require 'date'
require 'active_support/all'

class Post
  def initialize(title, slug, filename, publish_date, tags)
  	@title = title
  	@slug = slug
    @filename = filename 
    @publish_date = publish_date
    @tags = tags
  end
end

class Tag
  def initialize(name, count)
    @name = name
    @count = count
  end
end

class BlogBuilder
  class << self

    attr_reader :posts, :json_string

    def set_post_metadata
      @posts = []
      Dir.glob('./content/posts/*.md').each do |item|
        title = File.open(item, &:readline)
        title = title.gsub("\n", "")
        title[0] = ''
        title = title.strip
        slug = item[0...-3]
        publish_date = `git log --format='format:%ci' --diff-filter=A "#{item}"`
        tags = create_meta_data_for_post(slug)
        @posts.push(Post.new(title, slug, item, publish_date, tags))
      end
    end

    def create_meta_data_for_post(post_slug)
      @tags = []
      tag_file = post_slug + ".json"
      if File.exists?(tag_file)
        post_meta = JSON.parse(IO.read(tag_file))
        unless post_meta['tags'].nil?
          post_meta['tags'].each do |tag|
              @tags.push(Tag.new(tag['name'], 1))
          end
        end
      end
      return @tags
    end

    def jsonify_posts
      posts = @posts.sort_by { |post| DateTime.parse(post.instance_variable_get(:@publish_date)) }
      @json_string = posts.reverse.to_json
    end

    def create_posts_from_json
      File.open('./content/posts.json', 'w') { |f| f.write(json_string) }
    end

    def commit
      `git add .`
      puts `git commit -m "Empress built - #{Time.now}"`
    end

    def build!
      set_post_metadata
      jsonify_posts
      create_posts_from_json
      commit
    end
  end
end

BlogBuilder.build!
