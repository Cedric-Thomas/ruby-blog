require('fileutils')
require('asciidoctor')
require('erb')

load('config.rb')

def partial(p)
    p_path = "partials/#{p}.erb"
    if(File.file?(p_path))
        return ERB.new(
            File.read(p_path),
            trim_mode: "%<>"
        ).result(binding)
    end
end

def apply_layout(content, dom)
    
    @content = content

    if(dom[:layout].nil? or dom[:layout].empty?)
        dom[:layout] = "default"
    end

    l_path = "layouts/#{dom[:layout]}.erb"

    if(File.file?(l_path))
        dom[:layout] = nil

        @content = ERB.new(
            File.read(l_path),
            trim_mode: "%<>"
        ).result(binding)

        if(not dom[:layout].nil?)
            apply_layout(@content, dom)
        end

        return @content
    else
        puts("err: layout not found")
    end
end

pages = Dir.glob("pages/**/*")

pages.each do |page|

    dom     = Dom
    content = nil

    if(File.extname(page) == ".adoc")
            
        adoc = Asciidoctor.load_file(page)
        
        #puts(adoc.attributes)

        dom[:layout] = adoc.attributes["layout"]
        dom[:lang]   = adoc.attributes["lang"]

        content = adoc.render()

    end

    if(File.extname(page) == ".erb" or not content.nil? )
        
        if(content.nil?)
            content = ERB.new(
                File.read(page),
                trim_mode: "%<>"
            ).result(binding)
        end

        d_path = page.sub("pages", "dist").sub(/\.\w*/, ".html")
        FileUtils.mkdir_p(File.dirname(d_path))
        File.write(
            d_path,
            apply_layout(
                content,
                dom
            )
        )

    end
end