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

  def code(section, root:, file:, hide:nil)
    Torture::Snippet.(root: root, file: file, marker: section, hide: hide)
  end

  def show(snippet:)
    render view: "#{snippet}.md"
  end
end

File.write( "2.1/index.md", Bla.().() )
