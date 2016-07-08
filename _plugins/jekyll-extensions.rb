module Jekyll
  class LiquidRenderer
    class File
      # def initialize(renderer, filename)
      #   @renderer = renderer
      #   @filename = filename
      # end

      def parse(content)
        measure_time do
          @template = Liquid::Template.parse(content, line_numbers: true, filename: @filename)
        end

        self
      end
    end
  end
end
