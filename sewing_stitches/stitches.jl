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
include("elt.jl")

include("stitch_definitions.jl")

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
            #=
            elt("circle",
                :r => svg_unitless(PUNCH_RADIUS),
                :cx => svg_unitless(SVG_TEMPLATE_WIDTH / 2),
                :cy => svg_unitless(end_margin + i * stitch.paracord_hole_spacing),
                :class => "punch-hole")
            =#
            elt("rect",
                :x => svg_unitless(SVG_TEMPLATE_WIDTH / 2 - PUNCH_RADIUS),
                :y => svg_unitless(end_margin + i * stitch.paracord_hole_spacing - PUNCH_RADIUS),
                :width => svg_unitless(2 * PUNCH_RADIUS),
                :height => svg_unitless(2 * PUNCH_RADIUS),
                :class => "punch-hole")
        end...)
end

