
svg_inch(q) = @sprintf("%2.4fin", svgdistance(uconvert(u"inch", q)))

svg_unitless(q) = @sprintf("%2.4f", svgdistance(uconvert(u"inch", q)))

"""
    svgdistance(d)

Turn a Unitful length quantity to a floating point number we can use in SVG.
"""
function svgdistance(d)::Real
    ustrip(Float32, u"inch", d)
end


elt(tagname::AbstractString, things...) = elt(identity, tagname, things...)

"""
    elt(f, tagname::AbstractString, things...)
    elt(tagname::AbstractString, things...)

Return an XML element.  `f` is called with a single argument: either
an XML.AbstractXMLNode or a Pair describing an XML attribute to be added to the
resulting element.
"""
function elt(f::Function, tagname::AbstractString, things...)
    attributes = OrderedDict()
    children = Vector{Union{String, XML.AbstractXMLNode}}()
    function add_thing(s)
        if s isa Pair
            attributes[Symbol(s.first)] = XML.escape(string(s.second))
        elseif s isa AbstractDict    # set of attributes, e.g. from attributes(::XML.Node):
            for (k, v) in s
                attributes[Symbol(k)] = v
            end
        elseif s isa AbstractString
            push!(children, s)
        elseif s isa Number
            push!(children, string(s))
        elseif s isa XML.AbstractXMLNode
            push!(children, s)
        elseif s isa Nothing
            # Ignore
        else
            error("unsupported XML content: $s")
        end
    end
    for thing in things
        add_thing(thing)
    end
    f(add_thing)
    Node(XML.Element, tagname, attributes, nothing, children)
end

