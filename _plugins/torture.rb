module Torture
  module SnippetFilter
    def tsnippet(input, hide=nil)
      file, section = input.split(":")

      code = nil
      ignore = false
      File.open("../trailblazer/test/docs/#{file}").each do |ln|
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
        code = "" if ln =~ /\#:#{section}/ # beginning of our section.
      end

      indented = ""
      code.each_line { |ln| indented << "  "+ln }

      Kramdown::Document.new(indented).to_html
    end
  end
end

Liquid::Template.register_filter(Torture::SnippetFilter)
