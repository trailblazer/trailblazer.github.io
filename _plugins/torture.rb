require "torture/snippet"
module Torture
  module SnippetFilter
    def tsnippet(input, hide=nil)
      file, section, root, branch = input.split(":")

      root ||= "../trailblazer/test/docs"

      if branch
        original_branch = `cd #{root}; git branch`.match(/\*(.+)\n/)[1]
        `cd #{root}; git checkout #{branch}`
      end

      Torture::Snippet.(root: root, file: file, marker: section, hide: hide).tap do
        `cd #{root}; git checkout #{original_branch}` if branch
      end
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
