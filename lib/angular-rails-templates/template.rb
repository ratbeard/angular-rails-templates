require 'angular-rails-templates/compact_javascript_escape'

module AngularRailsTemplates
  class Template < ::Tilt::Template
    include CompactJavaScriptEscape
    AngularJsTemplateWrapper = Tilt::ERBTemplate.new "#{File.dirname __FILE__}/javascript_template.js.erb"
    @@compressor = nil

    # This line adds a trailing ';' to all svg files that sprockets sees, including ones we
    # don't want to turn into angular templates, effectively making svg processing useless as
    # it breaks svg's used from css :(
    # https://github.com/sstephenson/sprockets/blob/e22d736f671315a01d3eb932698b773c5a21b6b6/lib/sprockets/utils.rb#L101
    def self.default_mime_type
      'application/javascript'
    end

    def prepare
      # we only want to process html assets inside the configured root dir (defaults to Rails.root/app/assets).
      @asset_inside_root_dir = file.match configuration.root_dir
      puts file, @asset_inside_root_dir

      if configuration.htmlcompressor and @asset_inside_root_dir
        @data = compress data
      end
    end

    def evaluate(scope, locals, &block)
      locals[:html] = escape_javascript data.chomp
      locals[:angular_template_name] = logical_template_path(scope)
      locals[:source_file] = "#{scope.pathname}".sub(/^#{Rails.root}\//,'')
      locals[:angular_module] = configuration.module_name

      if @asset_inside_root_dir
        AngularJsTemplateWrapper.render(scope, locals)
      else
        data
      end
    end

    private

    def logical_template_path(scope)
      path = scope.logical_path.sub /^(#{configuration.ignore_prefix.join('|')})/, ''
      if configuration.include_svg && scope.pathname.extname == '.svg'
        "#{path}.svg"
      else
        "#{path}.html"
      end
    end

    def configuration
      ::Rails.configuration.angular_templates
    end

    def compress html
      unless @@compressor
        @@compressor = HtmlCompressor::Compressor.new configuration.htmlcompressor
      end
      @@compressor.compress(html)
    end
  end
end

