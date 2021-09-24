# MIT licence <cedric.thomas>

require('fileutils')
require('asciidoctor')
require('erb')
require('ostruct')

# loding config.rb
# where we store the default dom props
load('config.rb')

#------------------------------------------------------------------------------#
def __render(path, context)
  if(File.file?(path))
    return ERB.new(
      File.read(path),
      trim_mode: "%<>"
    ).result(context)
  end
end

def partial(p, _o = nil)
  p_path = "partials/#{p}.erb"
  return __render(p_path, binding)
end

def component(trgt, data)
  return partial(trgt, data)
end
#------------------------------------------------------------------------------#



#------------------------------------------------------------------------------#
module Empty
  def self.binding
    super
  end
end

class Page
  def initialize(path)
    # black magic
    @binding  = binding

    @path     = path
    @dom      = Dom
    @content  = nil
    @rendered = nil

    @type     = File.extname(@path)
  end

  def content()
    if(@content.nil?) 
      if(@type == ".erb")
        @content = __render(@path, @binding)
        return
      end
      
      if(@type == ".adoc")
        adoc = Asciidoctor.load_file(@path)
        # create a banlist with default's asciidoc attributes
        ban  = Asciidoctor.load("").attributes.keys
        adoc.attributes.each do |key, val|
          # if key in banlist then not pushing it
          @dom[key.to_sym()] = val unless ban.include?(key)
        end
        @content = adoc.render()
      end
    end
  end

  def dom()
    self.content() if @content.nil?
    return @dom
  end

  def render()
    if(@rendered.nil?)
      if(@content.nil?)
        self.content()
      end

      @dom.layout = "default" if @dom.layout.empty?

      l_path = "layouts/#{@dom.layout}.erb"

      @dom.layout = nil
      @content = __render(l_path, @binding)

      self.render() unless @dom.layout.nil?

      @rendered = @content

    end
    return @rendered
  end

  def write(path = "")
    if(path.empty?)
      # TODO: create an method to handle that kind of path hacks
      path = @path.sub("pages", "dist").sub(/\.\w*/, ".html")
    end
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, self.render())
  end
end
#------------------------------------------------------------------------------#

# main

pages = Dir.glob("pages/**/*.{erb,adoc}")

pages.each do |page_path|
  Page.new(page_path).write()
end

# copying public content to dist
FileUtils.cp_r("public", "dist/")
