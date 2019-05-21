require 'cgi'
require 'json'

module WebpackHelpers
  def javascript_tag(name)
    html = asset_uris(name, 'js').map {|uri|  %{<script src="#{CGI.escapeHTML(uri)}"></script>} }.join
    html = html.html_safe if html.respond_to?(:html_safe)
    html
  end

  def stylesheet_tag(name)
    html = asset_uris(name, 'css').map {|uri|  %{<link rel="stylesheet" href="#{CGI.escapeHTML(uri)}">} }.join
    html = html.html_safe if html.respond_to?(:html_safe)
    html
  end

  def asset_uris(name, type)
    asset_paths(name, type).map {|path| "#{assets_base_uri}/#{path}" }
  end

  private

  MANIFEST_PATH = 'public/assets/manifest.json'.freeze
  def manifest
    if !@manifest || (settings.development? && @manifest_mtime < File.stat(MANIFEST_PATH).mtime)
      File.open(MANIFEST_PATH) do |f|
        @manifest_mtime = f.stat.mtime
        @manifest = JSON.parse(f.read)
      end
    end

    @manifest
  end

  def entrypoints
    manifest.fetch('entrypoints')
  end

  def asset_paths(name, type)
    entrypoints.fetch(name).fetch(type)
  end

  def assets_base_uri
    @assets_base_uri ||= ENV.fetch('WEBPACK_DEV_SERVER_URL', settings.assets_uri)
  end
end