#!/usr/local/bin/ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'readline'


# Copyright (c) 2010 Michael Dvorkin
#
# Awesome Print is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
class String

  [ :gray, :red, :green, :yellow, :blue, :purple, :cyan, :white ].each_with_index do |color, i|
    if STDOUT.tty? && ENV['TERM'] && ENV['TERM'] != 'dumb'
      define_method color          do "\033[1;#{30+i}m#{self}\033[0m" end
      define_method :"#{color}ish" do "\033[0;#{30+i}m#{self}\033[0m" end
    else
      define_method color do self end
      alias_method :"#{color}ish", color 
    end
  end

  alias :black :grayish
  alias :pale  :whiteish

end

loop do

  # print "(Ctrl + D to exit): "
  break unless query = Readline.readline('(Ctrl + D to exit): ', true)
  query.strip!
  result_page = Nokogiri::HTML(open("http://www.google.com/dictionary?langpair=en%7Czh-TW&q=#{query}&hl=en&aq=f"))

  IO.popen('less -R -', 'w') do |less|
    old = $stdout
    $stdout = less

    puts query.yellow

    if !result_page.css('.err').empty?
      puts result_page.css('.err').inner_text.red
    else
      result_page.css('li.dct-ec').each do |block|
        # 詞類
        puts block.at_css('span.dct-elb').inner_text.green
        block.css('div.dct-em').each_with_index do |description_block, i|
          print "#{i+1}: ".yellow
          description_block.css('span.dct-tt').each do |description|
            puts "\t" + description.inner_html.gsub(%r(<span.*?>.*?</span>), '')
            description.css('span').each do |other|
              puts "\t" + other.inner_text.cyan + " (#{other.attribute('title')})"
            end
          end
        end
      end
    end
    result_page.css('.wd').each do |wd|
      puts wd.inner_text.gray
      formated = []
      wd.next_element.css('.wbtr_mn').each do |mn|
        formated << mn.inner_text
      end
      puts formated.join(', ')
    end
    less.close_write
    $stdout = old
  end

end
