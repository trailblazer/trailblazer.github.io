module Jekyll
  class TabsTag < Liquid::Block
    include Liquid::StandardFilters

    def initialize(tag, options, liquid_options)
      super
      # @liquid_options = liquid_options
      @filename       = liquid_options[:filename]
      @code     = options.include? "code" # This tab only contains a code block
    end

    def identifier(index, name)
      slug = name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '') # http://stackoverflow.com/questions/4308377/ruby-post-title-to-slug
      # slug #=> "rails"

      sprintf("tabs-%s-%s-%s", @panel_id, index, slug)
    end

    def render(context)
      markup = super

      # in case the liquid "API" changes.
      raise unless @filename
      raise unless line_number
      @panel_id = sprintf("%s-%s", @filename, line_number) # ID for tabs block.
      @panel_id = @panel_id.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '') # gemscellsgetting-startedmd-17


      blocks = markup.split("~~").drop(1) # The first block starts with ~~, so drop everything before this first ~~.

      # puts "@@@@@ #{@filename.inspect}"
      #  pp line_number
      # pp @filename

      tabs = {}
      blocks.each do |section|
        section = section.split("\n")
        tabs[section.shift] = section.join("\n")
      end

      # { Ruby: "..", Rails: "" }
      titles = tabs.keys.collect.with_index do |tab, index|
        classes = ["tabs-title"]
        classes << "is-active" if index == 0
        sprintf("<li class='%s'><a href='#%s'>%s</a></li>",
                classes.join(" "),
                identifier(index, tab),
                tab
        )
      end
      contents = tabs.collect.with_index do |(tab, content), index|
        classes = ["tabs-panel"]
        classes << "is-active" if index == 0
        sprintf("<div class='%s' id='%s'>%s</div>",
                classes.join(" "),
                identifier(index, tab),
                Kramdown::Document.new(content).to_html
        )
      end


%{
<div class="#{@code ? "tabs-container code-only" : "tabs-container"}">
  <ul class="tabs" data-tabs id="#{@panel_id}">#{titles.join("\n")}</ul>
  <div class="tabs-content" data-tabs-content="#{@panel_id}">
    #{contents.join("\n")}
  </div>
</div>
}
    end
  end
end

Liquid::Template.register_tag('tabs', Jekyll::TabsTag)

