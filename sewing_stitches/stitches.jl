using Pkg
using Printf
Pkg.activate(; temp=true)
Pkg.add("Unitful")
using Unitful
Pkg.add("UnitfulUS")
using UnitfulUS
Pkg.add("XML")
using XML
Pkg.add("OrderedCollections")
using OrderedCollections

println()


SEWING_STITCHES = Dict()

struct SewingStitch
    iso_number::Int
    name::String
    number_of_threads::Int
    confined_to_edge::Bool
    description::String
    paracord_hole_spacing

    SewingStitch(; iso_number, name, number_of_threads,
                 confined_to_edge, description, paracord_hole_spacing) =
                     SewingStitch(iso_number, name, number_of_threads, 
                                  confined_to_edge, description,
                                  paracord_hole_spacing)

    function SewingStitch(args...)
        s = new(args...)
        SEWING_STITCHES[s.iso_number] = s
        s
    end
end

Base.isless(stitch1::SewingStitch, stitch2::SewingStitch) =
    stitch1.iso_number < stitch2.iso_number

function html_file_name(stitch::SewingStitch)
    name = replace(stitch.name, ' ' => '_')
    "$(stitch.iso_number)-$name.html"
end


################################################################################
# 503, 504

# 301 https://www.youtube.com/watch?v=zk9h8ByMcvg
# 401 https://www.youtube.com/watch?v=jEr_SNFMIqw
# 504 https://www.youtube.com/watch?v=KMrsT6jPR7s
# 605 https://www.youtube.com/watch?v=wH4mEIRzwOU

#=  Template:
SewingStitch(
    iso_number = 
    name = 
    number_of_threads = 
    confined_to_edge = 
    description = 
    paracord_hole_spacing = 
)
=#

SewingStitch(
    iso_number = 101,
    name = "Single Thread Chain Stitch",
    number_of_threads = 1,
    confined_to_edge = false,
    description = """

        The single threaded needle passes into the fabric to form a
        loop un the underside.  A hook catches that loop and pulls it
        through the loop from the previous stitch.

    """,
    paracord_hole_spacing = 0.5 * u"inch")

SewingStitch(
    iso_number = 209,
    name = "Straight or Running Stitch",
    number_of_threads = 1,
    confined_to_edge = false,
    description = """

        This is a common stitch used in hand sewing.  Start with a
        threaded needle above the fabric.  The needle is passed down
        through the fabric and the thread pulled tight.  Then the
        needle is passed back up through the fabric at the next
        location and the thread pulled tight.

""",
    paracord_hole_spacing = 0.5 * u"inch")

SewingStitch(
    iso_number = 301,
    name = "Lockstitch",
    number_of_threads = 2,
    confined_to_edge = false,
    description = """

    This is the fundamental stitch of machine sewing.  The top thread
    is threaded through a needle.  The bottom thread is wound around a
    floating bobbin.  The needle passes into the fabric.  As it is
    withdrawn the top thread forms a loop under the fabric.  a hook
    catches that loop and pulls it under and around the floating
    bobbin.  This has the effect of passing the bobbin thread through
    the loop in the top thread.  Once the needle is fully withdrawn
    and the top thread pulled taught, the crossing of the top and
    bottom threads is pulled into the fabric.

""",
    paracord_hole_spacing = 0.75 * u"inch")

SewingStitch(
    iso_number = 503,
    name = "Two Thread OverEdge (Serging)",
    number_of_threads = 2,
    confined_to_edge = true,
    description = """

    The top thread is threaded through a needle.  The edge thread is
    threaded through a looper.  The looper can move the edge thread
    around the edge to either surface of the fabric.  With the looper
    holding a loop of the bottom thread on the upper surface of the
    fabric, the needed passes the top thread through that loop and
    through the fabric.

    """,
    paracord_hole_spacing = 0.75 * u"inch")

################################################################################

# These web pages format properly in Safari, but in Chrome for
# printing, the punch holes are on a separate page.

SHEET_WIDTH = 8 * u"inch"
SHEET_HEIGHT = 10 * u"inch"
SVG_TEMPLATE_WIDTH = 1 * u"inch"
PUNCH_RADIUS = 0.125 * u"inch" / 2


include("elt.jl")

STYLESHEET = """
h1 {
    font-size: 0.25in;
}

.thread-count {
    text-align: end;
}

.page {
    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
    page-break-inside: avoid;
}

.text {
    display: inline-block;
    flex-grow: 1;
    width: 2in;
}

.example-stitches {
    display: inline-block;
    margin: 0;
}

punch-hole {
    fill: blue;
    stroke-width: 0;
}

@page {
    size: $(svg_inch(SHEET_WIDTH)) $(svg_inch(SHEET_HEIGHT)) portrait;
    margin-top: 0.5in;
    margin-bottom: 0.5in;
    margin-left: 1in;
    margin-right: 0.25 in;
}

@media print {
    .page {
    }
}

"""


function svg_punch_template(stitch::SewingStitch)
    vpwidth = svgdistance(SVG_TEMPLATE_WIDTH)
    vpheight = svgdistance(SHEET_HEIGHT)
    punch_count = floor(Int, (SHEET_HEIGHT - 1 * u"inch") / (stitch.paracord_hole_spacing))
    end_margin = (SHEET_HEIGHT - (punch_count - 1) * stitch.paracord_hole_spacing) / 2
    elt("svg",
        :xmlns => "http://www.w3.org/2000/svg",
        :width => svg_inch(SVG_TEMPLATE_WIDTH),
        :height => svg_inch(SHEET_HEIGHT),
        :viewBox => "0 0 $vpwidth $vpheight",
        :preserveAspectRatio => "xMaxyMid",
        map(0 : (punch_count - 1)) do i
            elt("circle",
                :r => svg_unitless(PUNCH_RADIUS),
                :cx => svg_unitless(SVG_TEMPLATE_WIDTH / 2),
                :cy => svg_unitless(end_margin + i * stitch.paracord_hole_spacing),
                :class => "punch-hole")
        end...)
end


function format_stitch_page(stitch::SewingStitch)
    doc =
        elt("html",
            elt("head",
                elt("style", STYLESHEET)),
            elt("body",
                elt("div", "class" => "page",
                    elt("div", "class" => "text",
                        elt("h1", "$(stitch.iso_number) - $(stitch.name)"),
                        elt("div", "class" => "thread-count",
                            "$(stitch.number_of_threads) threads"),
                        elt("p", stitch.description)),
                    elt("div", "class" => "example-stitches",
                        # We want to run an SVG line of dots to serve as the hole
                        # punch template along the right edge.  Should we do that
                        # as a grid or an overlay?
                        svg_punch_template(stitch)))))
    filename = joinpath(@__DIR__, html_file_name(stitch))
    XML.write(filename, doc)
    println("Wrote $filename")
end

for stitch in values(SEWING_STITCHES)
    format_stitch_page(stitch)
end


function autogenerate_pages(io::IO)
    for stitch in sort(collect(values(SEWING_STITCHES)))
        println(io, "- [$(stitch.iso_number)-$(stitch.name)]($(html_file_name(stitch)))")
    end
end

AUTOGENERATED_RE = r"^ *<!-- +(?<op>BEGIN|END) +AUTOGENERATED +(?<autogen>[a-zA-Z0-9]+) +--> *$"

AUTOGEN_OPS = Dict(
    "Pages" => autogenerate_pages
)


function update_readme()
    readme_file = joinpath(@__DIR__, "README.md")
    input_readme = open(readme_file, "r") do io
        read(io, String)
    end
    open(readme_file, "w") do io
        discarding = false
        for line in split(input_readme, "\n")
            m = match(AUTOGENERATED_RE, line)
            # println(discarding, "\t", m, "\t", line)
            if m == nothing
                if !discarding
                    println(io, line)
                end
            else
                if m[:op] == "BEGIN"
                    println(io, line)
                    discarding = true
                elseif m[:op] == "END"
                    discarding = false
                    # Now generate the new output:
                    autogenerate_pages(io)
                    println(io, line)
                else
                    error("Unsupported op in $m")
                end
            end
        end
    end
end

update_readme()

