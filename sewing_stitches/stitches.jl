using Pkg
using Printf
import Markdown
using Markdown: @md_str
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


################################################################################
# Substrate for representing stitch types:

SEWING_STITCHES = Dict()

struct SewingStitch
    iso_number::Int
    name::String
    number_of_threads::Int
    confined_to_edge::Bool
    reidermeister_only::Bool
    description
    paracord_hole_spacing

    SewingStitch(; iso_number, name, number_of_threads,
                 confined_to_edge, reidermeister_only,
                 description, paracord_hole_spacing) =
                     SewingStitch(iso_number, name, number_of_threads, 
                                  confined_to_edge, reidermeister_only,
                                  description, paracord_hole_spacing)

    function SewingStitch(args...)
        s = new(args...)
        SEWING_STITCHES[s.iso_number] = s
        s
    end
end

Base.isless(stitch1::SewingStitch, stitch2::SewingStitch) =
    stitch1.iso_number < stitch2.iso_number


################################################################################
# Includes:

include("readme_tools.jl")
include("generate_html.jl")

################################################################################
# These are the stitch types we will document:

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
    reidermeister_only =
    description = 
    paracord_hole_spacing = 
)
=#

SewingStitch(
    iso_number = 101,
    name = "Single Thread Chain Stitch",
    number_of_threads = 1,
    confined_to_edge = false,
    reidermeister_only = true,
    description = """

        A hook on the under side of the fabric is holding the loop
        from the previous stitch.  The threaded needle passes into the
        fabric and through that loop and forms a new loop on the
        underside. The hook drops the previous loop and catches the
        new one.  The needle is retracted and the fabric advanced,
        pulling the stitch tight.

    """,
    paracord_hole_spacing = 0.5 * u"inch")

SewingStitch(
    iso_number = 209,
    name = "Straight or Running Stitch",
    number_of_threads = 1,
    confined_to_edge = false,
    reidermeister_only = false,
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
    reidermeister_only = false,
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
    reidermeister_only = true,
    description = """

    The top thread is threaded through a needle.  The edge thread is
    threaded through a looper.  The looper can move the edge thread
    around the edge to either surface of the fabric.  With the looper
    holding a loop of the bottom thread on the upper surface of the
    fabric, the needle passes the top thread through that loop and
    through the fabric.  The looper moves to the underside of the
    fabrid and catches the loop of the needle thread as the needle
    retracts, passing a new loop of the looper thread through the loop
    in the needle thread before the looper returns to the top surface
    of the fabric for the next stitch.

    """,
    paracord_hole_spacing = 1 * u"inch")

SewingStitch(
    iso_number = 504,
    name = "Three Thread OverEdge (Serging)",
    number_of_threads = 3,
    confined_to_edge = true,
    reidermeister_only = true,
    description = md"""

    This stitch uses one top needle and two loopers.  We start with
    the needle in its topmost position, the upper looper holding a
    loop of its thread across the top surface of the fabric under the
    needle, and the lower looper retracted at its poinit of motion
    that is furthest from the edge of the fabric.

    - The upper needle passes a loop of the needle thread through that
      loop and the fabric.

    - The lower loopper moves towards the edge while passing a loop
      of its thread through the needle thread loop under the fabric.
      Meanwhile, the upper looper moves to the edge of the fabric.

    - Next the lower looper pulls a loop of its thread to the edge of
      the fabric.

    - Finally, the upper looper passes a loop of its thread through
      that loop of the lower looper's thread and returns to its starting
      position.

    """,
    paracord_hole_spacing = 1.5 * u"inch"
)

################################################################################
# Here we generate an SVG file for each stitch type:

# These web pages format properly in Safari, but in Chrome for
# printing, the punch holes are on a separate page.

SHEET_WIDTH = 8 * u"inch"
SHEET_HEIGHT = 10 * u"inch"
SVG_TEMPLATE_WIDTH = 1.5 * u"inch"     # The margin where the punch holes go.
PUNCH_RADIUS = 0.125 * u"inch" / 2

# The distance of the punch holes from the edge is half of
# SVG_TEMPLATE_WIDTH.


include("elt.jl")

STYLESHEET = """
body {
    font-family: sans-serif;
    margin-top: 0;
    margin-bottom: 0;
    margin-left: 0;
    margin-right: 0;
    border: 1px;
}

.title {
    font-size: 0.4in;
    text-align: center;
    margin-top: 0.75in;
}

.thread-count {
    text-align: end;
    margin-top: 2ex;
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
    margin-right: 0.25in;
    font-size: 0.3in;
}

punch-hole {
    fill: blue;
    stroke-width: 0;
}

@page {
    size: $(svg_inch(SHEET_WIDTH)) $(svg_inch(SHEET_HEIGHT)) portrait;
}

@media print {
    .page {
        padding: 0;
        margin-top: 0.5in;
        margin-bottom: 0.5in;
        margin-left: 1in;
        margin-right: 0.25in;
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
        :preserveAspectRatio => "xMaxYMin meet",
        elt("rect",
            "x" => 0,
            "y" => 0,
            "width" => SVG_TEMPLATE_WIDTH,
            "height" => SHEET_HEIGHT,
            "stroke-width" => "1px",
            "stroke" => "black",
            "fill" => "none"),
        map(0 : (punch_count - 1)) do i
            elt("circle",
                :r => svg_unitless(PUNCH_RADIUS),
                :cx => svg_unitless(SVG_TEMPLATE_WIDTH / 2),
                :cy => svg_unitless(end_margin + i * stitch.paracord_hole_spacing),
                :class => "punch-hole")
        end...)
end

