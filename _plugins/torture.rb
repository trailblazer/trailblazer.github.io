require "torture/snippet"
module Torture
  module SnippetFilter
    def tsnippet(input, hide=nil)
      file, section, root = input.split(":")

      root ||= "../trailblazer/test/docs"

      Torture::Snippet.(root: root, file: file, marker: section, hide: hide)
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
