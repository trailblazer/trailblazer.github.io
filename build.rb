require "trailblazer/cells"
require "cell/erb"

require "torture/snippet"
require "kramdown"


# {bla/index.md.erb} pulls in all snippets via the #snippet helper, then {2.1/index.md} get rendered.

class Bla < Trailblazer::Cell
  self.view_paths = ["./2.1"]
  include Cell::Erb

  def show
    render view: "index.md"
  end

  private

  # grab a source code snippet from a physical file.
  # Return its Markdown version.
  def snippet(name)
    Snippets.().(:show, snippet: name)
  end
end

class Snippets < Trailblazer::Cell
  self.view_paths = ["./2.1"]
  include Cell::Erb

  def extract(section, root:, file:, collapse:nil)
    Torture::Snippet.extract_from(file: File.join(root, file), marker: section, collapse: collapse)
  end

  def code(*args)
    %{```ruby
#{extract(*args)}```
}
  end

  def anchor(unique_name)
    # TODO: register that name in a "global" registry
    %{<a name="#{unique_name}" />

}

    "{##{unique_name}}\n\n" # return Kramdown's {#anchor-name}, see https://kramdown.gettalong.org/syntax.html#specifying-a-header-id
  end

  def show(snippet:)
    render view: "#{snippet}.md"
  end
end

File.write( "2.1/index.md", Bla.().() )
