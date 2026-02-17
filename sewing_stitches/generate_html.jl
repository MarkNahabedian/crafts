# HTML backend

function html_file_name(stitch::SewingStitch)
    name = replace(stitch.name,
                   ' ' => '_',
                   '(' => '_',
                   ')' => '_')

    "$(stitch.iso_number)-$name.html"
end

function description_html(stitch::SewingStitch)
    if stitch.description isa Markdown.MD
        parse(join(["<div>",
                    Markdown.html(stitch.description),
                    "</div>"]),
              XML.Node)
    else
        elt("div", stitch.description)
    end
end

function get_stylesheet()
    open(joinpath(@__DIR__, "stylesheet.css"), "r") do io
        String(read(io))
    end
end

function format_stitch_page(stitch::SewingStitch)
    doc =
        elt("html",
            elt("head",
                elt("style", get_stylesheet())),
            elt("body",
                elt("div", "class" => "page",
                    elt("div", "class" => "text",
                        elt("div", :class => "title",
                            "$(stitch.iso_number) - $(stitch.name)"),
                        elt("div", "class" => "thread-count",
                            "$(stitch.number_of_threads) threads"),
                        elt("p", description_html(stitch))),
                    elt("div", "class" => "example-stitches",
                        # We want to run an SVG line of dots to serve as the hole
                        # punch template along the right edge.  Should we do that
                        # as a grid or an overlay?
                        svg_punch_template(stitch)))))
    filename = joinpath(@__DIR__, html_file_name(stitch))
    XML.write(filename, doc)
    println("Wrote $filename")
end


function format_all_stitch_pages()
    for stitch in values(SEWING_STITCHES)
        format_stitch_page(stitch)
    end
end

