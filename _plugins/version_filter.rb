module VersionFilter
  def version_path(input, version)
    puts "@@@@@ #{input.inspect}"
    input.sub(/\d\.\d/, version).sub(".md", ".html")
  end
end

Liquid::Template.register_filter(VersionFilter)
