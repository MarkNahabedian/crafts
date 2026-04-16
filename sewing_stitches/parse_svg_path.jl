# Parse an SVG path d attribute into components.

using Pkg
Pkg.add("Parsers")
using Parsers
using Printf

abstract type SVGPathComponent end

function pathletter(cmd::SVGPathComponent)
    r = relative_pathletter(typeof(cmd))
    if cmd.relative
        lowercase(r)
    else
        uppercase(r)
    end
end

function to_string(cmds::Vector{SVGPathComponent})
    io = IOBuffer()
    for cmd in cmds
        if position(io) > 0
            write(io, " ")
        end
        to_string(io, cmd)
    end
    String(take!(io)) 
end

function to_string(cmd::SVGPathComponent)
    io = IOBuffer()
    to_string(io, cmd)
    String(take!(io))
end

function to_string(io::IOBuffer, cmd::SVGPathComponent)
    write(io, pathletter(cmd))
    for field in fieldnames(typeof(cmd))
        if field == :relative
            continue
        end
        write(io, " ")
        v = getfield(cmd, field)
        if v == true
            write(io, "1")
        elseif v == false
            write(io, "0")
        else
            @printf(io, "%f", v)
        end
    end
end

function end_point(cmd::SVGPathComponent, start_x::Real, start_y::Real)
    if cmd.relative
        (start_x + cmd.end_x, start_y + cmd.end_y)
    else
        (cmd.end_x, cmd.end_y)
    end
end


struct MoveTo <: SVGPathComponent
    relative::Bool
    end_x::Real
    end_y::Real
end

relative_pathletter(::Type{MoveTo}) = 'm'
parameter_count(::Type{MoveTo}) = 2


struct LineTo <: SVGPathComponent
    relative::Bool
    end_x::Real
    end_y::Real
end

relative_pathletter(::Type{LineTo}) = 'l'
parameter_count(::Type{LineTo}) = 2


struct Horizontal <: SVGPathComponent
    relative::Bool
    end_x::Real
end

relative_pathletter(::Type{Horizontal}) = 'h'
parameter_count(::Type{Horizontal}) = 1

function end_point(cmd::Horizontal, start_x::Real, start_y::Real)
    if cmd.relative
        (start_x + cmd.end_x, start_y)
    else
        (cmd.end_x, start_y)
    end
end


struct Vertical <: SVGPathComponent
    relative::Bool
    end_y::Real
end

relative_pathletter(::Type{Vertical}) = 'v'
parameter_count(::Type{Vertical}) = 1

function end_point(cmd::Vertical, start_x::Real, start_y::Real)
    if cmd.relative
        (start_x, start_y + cmd.end_y)
    else
        (start_x, cmd.end_y)
    end
end


struct ClosePath <: SVGPathComponent
    # The relative flag is irrelevant for ClosePath but by including
    # it we can eliminate some special cases.
    relative::Bool
end

relative_pathletter(::Type{ClosePath}) = 'z'
parameter_count(::Type{ClosePath}) = 0

struct BezierCurve <: SVGPathComponent
    relative::Bool
    control_x1::Real
    control_y1::Real
    control_x2::Real
    control_y2::Real
    end_x::Real
    end_y::Real
end

relative_pathletter(::Type{BezierCurve}) = 'c'
parameter_count(::Type{BezierCurve}) = 6


struct SymetricBezierCurve <: SVGPathComponent
    relative::Bool
    control_x2::Real
    control_y2::Real
    end_x::Real
    end_y::Real
end

relative_pathletter(::Type{SymetricBezierCurve}) = 's'
parameter_count(::Type{SymetricBezierCurve}) = 4


struct QuadraticBezierCurve <: SVGPathComponent
    relative::Bool
    control_x1::Real
    control_y1::Real
    end_x::Real
    end_y::Real
end

relative_pathletter(::Type{QuadraticBezierCurve}) = 'q'
parameter_count(::Type{QuadraticBezierCurve}) = 4

struct SymetricQuadraticBezierCurve <: SVGPathComponent
    relative::Bool
    end_x::Real
    end_y::Real
end

relative_pathletter(::Type{SymetricQuadraticBezierCurve}) = 't'
parameter_count(::Type{SymetricQuadraticBezierCurve}) = 2

struct Arc <: SVGPathComponent
    relative::Bool
    radius_x::Real
    radius_y::Real
    x_axis_rotation::Bool
    large_arc_flag::Bool
    sweep_flag::Bool
    end_x::Real
    end_y::Real

    Arc(relative::Bool,
        radius_x::Real, radius_y::Real,
        x_axis_rotation::Int,
        large_arc_flag::Int,
        sweep_flagW::Int,
        to_x::Real, to_y::Real) =
            new(relative, radius_x, radius_y,
                x_axis_rotation != 0,
                large_arc_flag != 0,
                sweep_flagW != 0,
                to_x, to_y)
end

relative_pathletter(::Type{Arc}) = 'a'
parameter_count(::Type{Arc}) = 7


SVG_PATH_COMMANDS = let
    d = Dict()
    for st in subtypes(SVGPathComponent)
        d[relative_pathletter(st)] = st
    end
    d
end


"""
    parse_svg_path(path::AbstractString, index=1)::Vector{SVGPathComponent}

Returns the parsed components of the SVG path `d` attribute string.
"""
function parse_svg_path(path::AbstractString, index=1)::Vector{SVGPathComponent}
    float_re = r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?"
    parsed = []
    implicit_cmd = (MoveTo, false)
    function skip()
        while index <= length(path) && path[index] in [' ', ',']
            index += 1
        end
    end
    while index <= length(path)
        skip()
        pathcmd = path[index]
        if isletter(pathcmd)
            relative = islowercase(pathcmd)
            pathcmd = lowercase(pathcmd)
            if !haskey(SVG_PATH_COMMANDS, pathcmd)
                error("Unknown SVG path command: $pathcmd")
            end
            cmdtype = SVG_PATH_COMMANDS[pathcmd]
            implicit_cmd = (cmdtype, relative)
            index += 1
            skip()
        end
        argcount = parameter_count(implicit_cmd[1])
        params = []
        for i in 1 : argcount
            m = match(float_re, path, index)
            if m === nothing
                error("Invalid number at $index of $path")
            end
            r = Parsers.xparse(Float64, m.match)
            push!(params, r.val)
            index += r.tlen
            skip()
        end
        push!(parsed, implicit_cmd[1](implicit_cmd[2], params...))
    end
    parsed
end

function path_points(cmds::Vector{SVGPathComponent})
    result = []
    x = 0.0
    y = 0.0
    push!(result, (x, y))
    for cmd in cmds
        if cmd isa ClosePath
            continue
        end
        x, y = end_point(cmd, x, y)
        push!(result, (x, y))
    end
    result
end


function Base.isapprox(cmd1::SVGPathComponent, cmd2::SVGPathComponent)
    if typeof(cmd1) != typeof(cmd2)
        return false
    end
    for field in fieldnames(typeof(cmd1))
        if field == :relative
            if cmd1.relative != cmd2.relative
                return false
            end
        else
            if !isapprox(getfield(cmd1, field), getfield(cmd2, field),
                         )
                return false
            end
        end
    end
    true
end

function Base.isapprox(cmds1::Vector{SVGPathComponent}, cmds2::Vector{SVGPathComponent})
    for (cmd1, cmd2) in zip(cmds1, cmds2)
        if !isapprox(cmd1, cmd2)
            return false
        end
    end
    true
end

# A simple test:
let
    d = "M 0,0.260416 H 24.930556 V -0.78125 H 0 Z"
    p = parse_svg_path(d)
    s = to_string(p)
    ps = parse_svg_path(s)
    if !isapprox(p, ps)
        println(p, "\n", ps)
    end
end

let
    d = "m 0.09558105,-0.49521213 v -0.0675456 c 0.06347657,-0.0059 0.10762533,-0.0160726 0.13264974,-0.0305176 0.0252279,-0.0146484 0.044047,-0.0489299 0.0565593,-0.10294597 h 0.0691732 V -1.3563368e-5 H 0.26037598 V -0.49521213 Z"
    p = parse_svg_path(d)
    s = to_string(p)
    ps = parse_svg_path(s)
    if !isapprox(p, ps)
        println(p, "\n", ps)
    end
end

