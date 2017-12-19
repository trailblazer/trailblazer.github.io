require "torture/snippet"
require "pp"

module Torture
  module SnippetFilter
    # {{ "activity_test.rb:trace-act:../trailblazer-activity/test/docs" | tsnippet }}

    def tsnippet(section, hide=nil)
      root, file, branch = nil


      if page_config = @context.registers[:page]["code"]
        root, file, branch = page_config.split(",")
      end

      # all options passed in explicitly, "old style"
      segments = section.split(":")

      if segments.size == 2
        file, section = segments

      elsif segments.size > 2
        file, section, root, branch = section.split(":")
      end

      puts "^^^ tsnippet configuration for #{@context.registers[:page]["path"]}:#{section} = #{root}/#{file},#{branch}"

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
