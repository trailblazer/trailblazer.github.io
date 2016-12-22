module Torture
  module SnippetFilter
    def tsnippet(input, hide=nil)
      file, section = input.split(":")

      file = "../trailblazer/test/docs/#{file}" unless file.match("/")

      code = nil
      ignore = false
      File.open(file).each do |ln|
        break if ln =~ /\#:#{section} end/

        if ln =~ /#~#{hide}$/
          ignore = true
          code << ln.sub("#~#{hide}", "# ...")
        end

        if ln =~ /#~#{hide} end/
          ignore = false
          next
        end

        next if ignore
        next if ln =~ /#~/

        code << ln and next unless code.nil?
        code = "" if ln =~ /\#:#{section}$/ # beginning of our section.
      end

      indented = ""
      code.each_line { |ln| indented << "  "+ln }

      Kramdown::Document.new(indented).to_html
    end
  end
end

Liquid::Template.register_filter(Torture::SnippetFilter)

# TODO: TEST :bla and :blabla (two different sections)


module Torture
  class CalloutTag < Liquid::Block
    include Liquid::StandardFilters

    def render(context)
      markup = super

%{<div class="callout">
  #{Kramdown::Document.new(markup).to_html}
</div>}
    end
  end
end

Liquid::Template.register_tag('callout', Torture::CalloutTag)


require "torture/foundation6"
module Torture
  class RowTag < Liquid::Block
    include Liquid::StandardFilters

    def initialize(tag, klass=nil, *)
      super
      @class = klass || "macro"
    end

    def render(*)
      Foundation6::Row.new.(super, section_class: @class)
    end
  end
end

Liquid::Template.register_tag('row', Torture::RowTag)


module Torture
  class KramdownTag < Liquid::Block
    include Liquid::StandardFilters

    def render(context)
      markup = super

      Kramdown::Document.new(markup).to_html
    end
  end
end

Liquid::Template.register_tag('md', Torture::KramdownTag)
