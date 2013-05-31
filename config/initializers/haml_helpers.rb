module Haml
  module Helpers
    module Handlebars
      def hb(exp, options=nil, &block)
        hb_tag("{{", "}}", exp, options, &block)
      end

      def hb!(exp, options=nil, &block)
        hb_tag("{{{", "}}}", exp, options, &block)
      end

      def hb_i18n(text, options=nil)
        hb_tag("{{", "}}", "i18n \"#{text}\"", options)
      end

      private
      def hb_tag(prefix, suffix, exp, options=nil, &block)
        args = ""
        unless !options or options.length == 0
          options.each {|key, value| args << " #{key}=\"#{value.to_s.gsub('\\', "").gsub('"', '\\"')}\""}
        end

        if block
          output = "#{prefix}##{exp}#{args}#{suffix}#{capture_haml(&block).strip}#{prefix}/#{exp.split(" ", 2).first}#{suffix}"
        else
          output = "#{prefix}#{exp}#{args}#{suffix}"
        end

        Haml::Util.rails_xss_safe? ? Haml::Util.html_safe(output) : output
      end
    end

    include Handlebars
  end
end