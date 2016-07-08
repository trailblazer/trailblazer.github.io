require "nokogiri"

module Jekyll
  module TOC
    def toctoctoc(html)
      doc = Nokogiri::HTML(html)

      # h2[:id] comes from kramdown/auto_ids.
      headers = doc.css("h2").collect do |h2|

        # FIXME: we don't apply that change, yet, as we only render the menu.
        h2["data-magellan-target"] = h2[:id]
        # h2.after(%{<a name="#{h2[:id]}"></a>})

        [h2[:id], h2.text]
      end

      content = headers.collect do |id, text|
        %{<li><a href="##{id}">#{text}</a></li>}
      end

      %{
        <ul class="vertical menu" data-magellan id="page-toc">
          #{content.join("\n")}
        </ul>
      }
    end # toctoctoc
  end
end

Liquid::Template.register_filter(Jekyll::TOC)
