module Torture
  module SnippetFilter
    def tsnippet(input)
      file, section = input.split(":")

      code = nil
      File.open("../trailblazer/test/docs/#{file}").each do |ln|
        break if ln =~ /\#:#{section} end/
        code << ln and next unless code.nil?
        code = "" if ln =~ /\#:#{section}/
      end

      indented = ""
      code.each_line { |ln| indented << "  "+ln }

      Kramdown::Document.new(indented).to_html
    end
  end
end

Liquid::Template.register_filter(Torture::SnippetFilter)
