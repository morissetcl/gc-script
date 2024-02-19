# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require "byebug"
require 'terminal-table'
require 'tinyurl_shortener'
require 'tty-link'

class Main
  class << self
    def fetch_html(link)
      html_file = URI.parse(link).open
      doc = Nokogiri::HTML(html_file)
      collect_item_info(doc)
    end


    def collect_item_info(doc)
      titles = []
      moula = []
      opening_date = []
      closing_date = []

      expedition = []
      urls = []

      # Item title
      doc.css('[headers="itemInfo"] > div').each do |item|
        link = TinyurlShortener.shorten("https://***/#{item.css('a:first').first["href"]}")
        url = TTY::Link.link_to("link", link)
        urls << url

        titles << item.text.strip
      end

      # # Moula
      doc.css('.table-display > .blue > dd > span').each do |item|
        moula << item.text.strip
      end

      # # # Date d'affichage
      doc.css('.table-display').children.map do |a|
        is_closing_date = a.previous&.previous&.text&.strip == "Date de fermeture :"
        is_opening_date = a.previous&.previous&.text&.strip == "Date d'affichage :"

        is_exp = a.attribute_nodes.last&.value == "shortFra blue"

        if a.children.first
          date = a.children.first.text.strip.split("@").first&.strip
          opening_date << date if is_opening_date
          closing_date << date if is_closing_date
        end

        expedition << a.text.strip if is_exp
      end

      rows =  titles.zip(moula).zip(opening_date).zip(closing_date).zip(expedition).zip(urls).map(&:flatten).sort_by{|q| q[3] }.reverse
      puts Terminal::Table.new :headings => ['Title', 'Current price', "Date affichage", "Date fermeture", "Livraison",  'Url'], :rows => rows
    end
  end
end

categories = [7200, 7000, 9800, 5555, 7800, 5800, 6700, 7700, 7100, 8300]
categories.each do |category|
  Main.fetch_html("https://***/mn-fra.cfm?&snc=wfsav&vndsld=0&sc=ach-shop&lci=&sf=ferm-clos&so=ASC&srchtype=&hpcs=#{category}&hpsr=&kws=&jstp=sly&str=1&&sr=1&rpp=25&so=DESC")
end
