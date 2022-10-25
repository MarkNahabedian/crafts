### A Pluto.jl notebook ###
# v0.19.14

using Markdown
using InteractiveUtils

# ╔═╡ c1d9224b-7b60-451c-8889-11f00833f1c2
begin
    using Pluto
    if ! @isdefined PlutoRunner
	Pluto.activate_notebook_environment(@__FILE__)
    end
end

# ╔═╡ 9c0b434e-571c-4181-9350-848d50ba42e9
begin
	using Base: @kwdef
	using Colors
	using Markdown
	using XML
	using OrderedCollections
	using LinearAlgebra
end

# ╔═╡ 89e97690-18a6-11ed-15e4-4bb0cd5b7c50
md"""
# Gray Code Tablet Weaving Pattern
"""

# ╔═╡ 581fda2d-0771-4283-8ca1-4b88cbeffecf
# Given an array that represewnts an image we want to weave, which dimension
# is the warp, and which is the weft?
"""
	longer_dimension_counts_weft(image)

Return an image with the dimensions possibly permuted such that each increment
in the first dimension counts a new row of the weft.  The second dimension
indexes the color of the visible warp thread for that row.
"""
function longer_dimension_counts_weft(image)
	if size(image)[1] < size(image)[2]
		permutedims(image, [2, 1])
	else
		image
	end
end	

# ╔═╡ 0baa4c77-bf7a-4d39-b964-d4636975f8fa
# XML.jl convenience function for making elements:
function elt(tag::String, stuff...)
    attributes = Dict{Symbol, String}()
    children = []
    for s in stuff
        if s isa Pair
            attributes[s.first] = string(s.second)
        elseif s isa Number
            push!(children, string(s))
        else
            push!(children, s)
        end
    end
    XML.Node(XML.ELEMENT_NODE, tag, attributes, children)
end

# ╔═╡ 590963b9-bd0f-4c32-a778-873d22ec9c0f
md"""
## Gray Code
"""

# ╔═╡ a3b3c00d-425d-4437-b964-50946b7e75b3
graycode(x) = xor(x, x >>> 1)

# ╔═╡ e147b976-9227-4d54-8b14-f05d8eb0d42e
gray_sequence = [digits(graycode(x); base = 2, pad = 8) for x in 0:63]

# ╔═╡ fcb7d96f-f2ce-44cb-ac86-3ef6a6195bf4
COLORS = [ RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1)]

# ╔═╡ b04d2b69-aa8a-4174-8ef8-3e6b797354e7
size(hcat(gray_sequence...))

# ╔═╡ 1cf1cf59-d324-447a-8a72-b393c96b549f
md"""
## Tablets

A tablet or card is a square piece of card stock.

It has a front and a back.

It has a hole on each of it's four corners.

When looking at the front of the card, the holes are labeled **A**,
**B**, **C**, and **D** clockwise.

The edges of the card are numbered, with the edge from corner **A** to
corner **B** numbered **1**.  The edge between **B** and **C** numbered **2**,
and so on around the card.

For weaving, one warp thread passes through each hole.

The four warp threads for a tablet pass from the warp beam,
through the tablet, to the cloth beam.  They can pass through the
tablet from `BackToFront` or `FrontToBack`.

Which thread passes through which hole, and how the tablet is
threaded, can not change once the loom is warped.

It's easier to think about how the stitches are formed if the
tablets are facing (either back or front depending on threading)
the weaver.  For compactness though the cards are stacked so that
the weaver is facing their edges.  When stacked, each tablet can
be oriented FrontToTheRight or FrontToTheLeft.

Which direction a tablet is facing when it is stacked can be changed
during weaving.

For each new row, each tablet must be rotated, and its stacking may
be flipped.  These operations affect the locations of the labeled
holes (and their warp threads) relative to the loom.
"""

# ╔═╡ 68c32382-4511-4345-a523-d9854b91e754
md"""
### Tablet Threading

How the warp threads pass through a tablet, the `TabletThreading`, can either be
`BackToFront` or `FrontToBack`.

for `BackToFront` threading, warp threads pass from the warp beam through the
tablet from back to front and then to the cloth beam.

For `FrontToBack` threading, Warp threads pass from the warp beam through the
tablet from front to back and then to the cloth beam.

These threadings also have a concise textual representation.  `BackToFront` can
be represented by `/`or `z`.  `BackToFront` can be represented by `\\` or `s`.
"""

# ╔═╡ 786f8502-a081-4baf-b82d-a936cdfaae5e
begin
    abstract type TabletThreading end

	"""
	Warp threads pass from the warp beam through the tablet from back to front.
	"""
    struct BackToFront <: TabletThreading end

	"""
	Warp threads pass from the warp beam through the tablet from front to back.
	"""
    struct FrontToBack <: TabletThreading end

    other(::BackToFront) = FrontToBack()
    other(::FrontToBack) = BackToFront()

	function threading_for_char(c::AbstractChar)
		if c == '/' || c == 'z' || c == 'Z'
			return BackToFront()
		end
		if c == '\\' || c == 's' || c == 'S'
			return FrontToBack()
		end
		error("Invalid threading designation: $c")
	end

	threading_char(::BackToFront) = '\u2571'
	threading_char(::BackToFront) = '\u2572'
end

# ╔═╡ 6d65f0b3-7370-4a7d-82bc-607f8b0f8c8c
md"""
### Tablet Stacking

If the tablets are arranged with a flat side facing the weaver this would take
too much space and also cause other inconveniences.  Instead, tablets are
arrahged so that their flat faces face each other.  This forms a horizontal
stack from one side of the loom to the other.

When stacked like this, a tablet is said to be stacked `FrontToTheRight` if
it's front face faces towards the right side of the loom rom the weaver's
perspective. A tablet facing the opposite direction is said to be threaded
`FrontToTheLeft`.

For brevity in textual representations, `FrontToTheRight` is represented with
a `→` right arrow and `FrontToTheLeft` with a `←` left arrow.
"""

# ╔═╡ b12c2fe2-a32e-4e6f-a7d7-cfc24e8cb00c
begin
    abstract type TabletStacking end

    struct FrontToTheRight <: TabletStacking end

    struct FrontToTheLeft <: TabletStacking end

    other(::FrontToTheRight) = FrontToTheLeft()
    other(::FrontToTheLeft) = FrontToTheRight()

	# An arrow showing which direction the front of a
	# tablet is currently facing.
	tablet_stacking_to_char(::FrontToTheRight) = '→'
	tablet_stacking_to_char(::FrontToTheLeft) = '←'
end

# ╔═╡ 0fea18b7-b40e-4ca5-95e5-744e619ea14a
@kwdef mutable struct Tablet{T}
	id = nothing
	a::T
	b::T
	c::T
	d::T
	threading::TabletThreading = BackToFront()
	# The above properties can not be changed after the loom has been warped.
	stacking::TabletStacking = FrontToTheRight()
	accumulated_rotation::Int = 0
	this_shot_rotation::Int = 0
	# It is helpful to know the range of thread twist imposed by a weaving pattern:
	min_rotation = 0
	max_rotation = 0
end

# ╔═╡ 61de53db-f01d-4294-8baf-d570abcd8d15
function copy(t::Tablet)
	@assert t.id == nothing
	@assert t.accumulated_rotation == 0
	@assert t.this_shot_rotation == 0
	@assert t.min_rotation == 0
	@assert t.max_rotation == 0
	Tablet(;
		id = t.id,
		a = t.a,
		b = t.b,
		c = t.c,
		d = t.d,
		threading = t.threading,
		stacking = t.stacking)
end

# ╔═╡ 31bdd4ca-aa24-4600-9a72-36410636019b
md"""
We use a `Vector` of `Tablet`s to describe how the loom is set up for
weaving.  for convenience, we can add these vectors together for a
wider pattern.  We can also multiply them to repeat tablets.
"""

# ╔═╡ bf12e28b-6bd1-45e3-9cea-e81d412c0097
begin
    function (Base.:+)(a::Tablet{<:Any}, b::Tablet{<:Any})
        [a; b]
    end

    function (Base.:+)(a::Tablet{<:Any}, v::Vector{<:Tablet{<:Any}})
        [a; v...]
    end

    function (Base.:+)(v::Vector{<:Tablet{<:Any}}, b::Tablet{<:Any})
		[v...; b]
    end

    function (Base.:+)(v1::Vector{<:Tablet{<:Any}}, v2::Vector{<:Tablet{<:Any}})
		[v1...; v2...]
    end

	function (Base.:+)(v1::Vector{<:Tablet{<:Any}}, vs::Vector{<:Tablet{<:Any}}...)
		result = v1
		for v2 in vs
			result += v2
		end
		result
    end

	function (Base.:*)(repeat::Int, t::Tablet{<:Any})
		result = Vector{Tablet{<:Any}}()
		for i in 1:repeat
		    push!(result, copy(t))
		end
		result
    end

    function (Base.:*)(repeat::Int, v::Vector{<:Tablet{<:Any}})
		result = Vector{Tablet{<:Any}}()
		for i in 1:repeat
		    append!(result, copy.(v))
		end
		result
    end
end

# ╔═╡ c2b1f51e-77fb-4e23-94cc-699c124b81c3
GRAY_PATTERN = map(hcat(gray_sequence...)) do bit
	COLORS[bit + 1]
end

# ╔═╡ 78e317ca-d347-45a9-9058-b2e7b187c843
GRAY_WEAVE = let
	# Reflect GRAY_PATTERN on both axes and add leading and trailing background:
	pattern = GRAY_PATTERN
	for _ in 1:4
		pattern = hcat(pattern[:, 1], pattern)
	end
	bottom = hcat(pattern, reverse(pattern; dims=2))
	vcat(reverse(bottom; dims=1), bottom)
end

# ╔═╡ 47320875-bad1-4528-8f78-82b017deedab
begin
	# The structure of a Tablet:

	TABLET_HOLE_LABELS = 'A':'D'
	TABLET_EDGE_LABELS = 1:4
	
	struct TabletHole
		label::Char

		function TabletHole(label::Char)
			@assert label in TABLET_HOLE_LABELS
			new(label)
		end
	end

	struct TabletEdge
		label::Int
	
		function TabletEdge(label::Int)
			@assert label in TABLET_EDGE_LABELS
			new(label)
		end
	end

	function modindex(index, seq)
		Int(mod(index - 1, length(seq)) + 1)
	end

	next(elt, seq) =
		seq[modindex(findfirst(x -> x == elt, seq) + 1, seq)]

	previous(elt, seq) =
		seq[modindex(findfirst(x -> x == elt, seq) - 1, seq)]

	function opposite(elt, seq)
		@assert iseven(length(seq))
		seq[
			modindex(findfirst(x -> x == elt, seq) + length(seq) / 2,
				seq)
		]
	end

	next(hole::TabletHole) = TabletHole(next(hole.label, TABLET_HOLE_LABELS))
	previous(hole::TabletHole) = TabletHole(previous(hole.label, TABLET_HOLE_LABELS))
	opposite(hole::TabletHole) = TabletHole(opposite(hole.label, TABLET_HOLE_LABELS))

	next(edge::TabletEdge) = TabletEdge(next(edge.label, TABLET_EDGE_LABELS))
	previous(edge::TabletEdge) = TabletEdge(previous(edge.label, TABLET_EDGE_LABELS))
	opposite(edge::TabletEdge) = TabletEdge(opposite(edge.label, TABLET_EDGE_LABELS))

	function next_hole(edge::TabletEdge)::TabletHole
		label = edge.label
		if label == 1 TabletHole('B')
		elseif label == 2 TabletHole('C')
		elseif label == 3 TabletHole('D')
		elseif label == 4 TabletHole('A')
		else error("Unsupported edge label: $label")
		end
	end

	function previous_hole(edge::TabletEdge)::TabletHole
		label = edge.label
		if label == 1 TabletHole('A')
		elseif label == 2 TabletHole('B')
		elseif label == 3 TabletHole('C')
		elseif label == 4 TabletHole('D')
		else error("Unsupported edge label: $label")
		end
	end
end

# ╔═╡ 8b85264e-25c8-4ae3-a952-ee30d622f918
begin
	for hole in TabletHole.(TABLET_HOLE_LABELS)
		@assert next(previous(hole))== hole
		@assert previous(next(hole)) == hole
		@assert opposite(opposite(hole)) == hole
	end
	
	for edge in TabletEdge.(TABLET_EDGE_LABELS)
		@assert next(previous(edge))== edge
		@assert previous(next(edge)) == edge
		@assert opposite(opposite(edge)) == edge
	end
	
	html"Tablet structure assertions pass"
end

# ╔═╡ a5796f2d-3754-4d99-9a37-2b476cc4f5a2
function warp_color(t::Tablet{T}, hole::TabletHole)::T where T
	h = hole.label
	if h == 'A' t.a
	elseif h == 'B' t.b
	elseif h == 'C' t.c
	elseif h == 'D' t.d
	else error("Unsuppoorted hole label: $h")
	end
end

# ╔═╡ 40bd184d-3332-49c0-a349-64b4e5fcc4aa
let
	border_color = RGB(0.5, 0.5, 0.5)
	border1 = Tablet(
		a=border_color,
		b=border_color,
		c=border_color,
		d=border_color,
		threading=BackToFront())

	tplust = 2 * border1
	@assert tplust isa Vector{Tablet{<:Any}}
	@assert length(tplust) == 2

	double = 2 * border1
	@assert double isa Vector{Tablet{<:Any}}
	@assert length(double) == 2

	@assert length(border1 + border1 + border1) == 3

	@assert length(2 * double) == 4

	@assert length(double + tplust) == 4

	@assert length(double + 3 * border1) == 5

	html"Tablet arithmetic assertions pass."
end

# ╔═╡ 56453fbd-6f6a-4c11-b2ba-acae84b66f48
md"""
### Tablet Rotation

Prior to each new throw of the weft, the tablets are rotated to
open a new shed.

In practice (the stacked arrangement), a card will be rotated
**forward** or **backward**.  Forward rotation moves the top
corner of the card closest to the weaver away from the weaver
towards the warp beam.  Backward rotation moves the top corner
furthest from the weaver toards the weaver.

Whether **forward** rotation turns the card in the **ABCD** or the 
**DCBA** direction depends on how the card is threaded and stacked.

"""

# ╔═╡ 86033a92-cd04-4c52-845d-89a8a473506c
"""
    RotationDirection

`RotationDirection` is the abstract supertype of all tablet rotations.
"""
abstract type RotationDirection end

# ╔═╡ f1c8a4c6-6c22-49f4-9df1-ef3ae5e3cb40
"""
    rotation(::Tablet, ::RotationDirection)

Return the change in the `Tablet`'s `accumulated_rotation` if the specified
`AbstractRotation is applied.
"""
function rotation(::Tablet, ::RotationDirection) end

# ╔═╡ 50e521b5-c4f7-464d-b6dd-5c7f9d5b4bd0
"""
    rotate!(::Tablet, ::RotationDirection)

Rotate the tablet by one position in the specified direction.
"""
function rotate!(t::Tablet, d::RotationDirection)
	new_rotation = rotation(t, d)
	t.this_shot_rotation += new_rotation
	return t
end

# ╔═╡ bb8a5f20-62af-4f28-b0df-85af57beb8f3
"""
The ABCD rotation causes the A corner of the tablet to move to
the location in space previously occupied by the B corner.
"""
struct ABCD <: RotationDirection end

# ╔═╡ 9d85d3ef-847b-405c-817b-71097b56fee5
rotation(::Tablet, ::ABCD) = 1

# ╔═╡ b3ec1ee7-77d8-417a-834a-70c6c6608ae7
"""
The DCBA rotation causes the A corner of the tablet to move to
the location in space previously occupied by the D corner.
"""
struct DCBA <: RotationDirection end

# ╔═╡ 748199f2-e5d8-4272-9120-f8b50264b5d6
rotation(t::Tablet, ::DCBA) = -1

# ╔═╡ e31dd514-64af-4491-aac2-b47a85372650
let
	bf = Tablet(; a=:A, b=:B, c=:C, d=:D, threading=BackToFront())
	rotate!(bf, ABCD())
	@assert bf.this_shot_rotation == 1
	rotate!(bf, DCBA())
	@assert bf.this_shot_rotation == 0
	html"ABCD and DCBA assertions passed."
end

# ╔═╡ b38913ac-f91f-4e6d-a95a-506b8d3c754c
"""
The `Clockwise` direction refers to how the tablet would move if its front or
back face (depending on threading) were facing the weaver.  Whether this
results in ABCD or DCBA rotation depends on how the card is threaded.
"""
struct Clockwise <: RotationDirection end

# ╔═╡ 8eea1d46-ca5b-48d4-9829-bce769dfcfbb
function rotation(t::Tablet, ::Clockwise)
	if t.threading isa BackToFront
		rotation(t, ABCD())
	else
		rotation(t, DCBA())
	end
end

# ╔═╡ f3a1f857-0d6c-4f29-8095-4c6f189b3604
"""
The `CounterClockwise` direction refers to how the tablet would move if its front
or back face (depending on threading)  were facing the weaver.  Whether the front
or the back of the tablet is facing the weaver depends on whether the card is
BackToFront` or `FrontToBack` threaded.
"""
struct CounterClockwise <: RotationDirection end

# ╔═╡ 82725eaa-1605-4471-a808-360d0693dd43
function rotation(t::Tablet, ::CounterClockwise)
	if isa(t.threading, FrontToBack)
		rotation(t, ABCD())
	else
		rotation(t, DCBA())
	end
end

# ╔═╡ 71e0104b-beb4-4e3e-8def-218f88fdfbcd
let
	bf = Tablet(; a=:A, b=:B, c=:C, d=:D, threading=BackToFront())
	rotate!(bf, Clockwise())
	@assert bf.this_shot_rotation == 1
	rotate!(bf, CounterClockwise())
	@assert bf.this_shot_rotation == 0
	
	fb = Tablet(; a=:A, b=:B, c=:C, d=:D, threading=FrontToBack())
	rotate!(fb, Clockwise())
	@assert fb.this_shot_rotation == -1
	rotate!(fb, CounterClockwise())
	@assert fb.this_shot_rotation == 0

	html"Clockwise and CounterClockwise rotate! assertions passed."
end

# ╔═╡ b901fcdd-31dc-4643-9dba-21e70207141b
"""
The Forward rotation moves the top corner of the tablet closest to the
weaver and the cloth beam to be the bottom corner closest to the weaver.
"""
struct Forward <: RotationDirection end

# ╔═╡ 30c08bee-e3f9-4672-a4d6-29df3ba8a6e5
function rotation(t::Tablet, ::Forward)
	if isa(t.stacking, FrontToTheRight)
		rotation(t, ABCD())
	else
		rotation(t, DCBA())
	end
end

# ╔═╡ 5498ffbc-40f9-44dd-9b6a-484e2498c406
"""
The Backward rotation moves the top corner of the tablet closest to the
weaver and the cloth beam to be the bottom corner closest to the weaver.
"""
struct Backward <: RotationDirection end

# ╔═╡ 6d796003-f336-44ed-8831-8ea2b56fe865
function rotation(t::Tablet, ::Backward)
	if isa(t.stacking, FrontToTheLeft)
		rotation(t, ABCD())
	else
		rotation(t, DCBA())
	end
end

# ╔═╡ 1b7b4e33-97c3-4da6-ad86-b9b4646dc619
begin
	tablet_rotation_char(::Forward) = "🡑"
	tablet_rotation_char(::Backward) = "🡓"
end

# ╔═╡ b396b71e-8510-4f7c-9017-50693b2f9c1d
let
	bf = Tablet(; a=:A, b=:B, c=:C, d=:D,
			threading=BackToFront(),
			stacking=FrontToTheRight())
	rotate!(bf, Forward())
	@assert bf.this_shot_rotation == 1
	rotate!(bf, Backward())
	@assert bf.this_shot_rotation == 0
	
	fb = Tablet(; a=:A, b=:B, c=:C, d=:D,
			threading=FrontToBack(),
			stacking=FrontToTheRight())
	rotate!(fb, Forward())
	@assert fb.this_shot_rotation == 1
	rotate!(fb, Backward())
	@assert fb.this_shot_rotation == 0

	bf.stacking = FrontToTheLeft()
	rotate!(bf, Forward())
	@assert bf.this_shot_rotation == -1
	rotate!(bf, Backward())
	@assert bf.this_shot_rotation == 0
	
	fb.stacking = FrontToTheLeft()
	rotate!(fb, Forward())
	@assert fb.this_shot_rotation == -1
	rotate!(fb, Backward())
	@assert fb.this_shot_rotation == 0

	html"Forward and Backward rotate! assertions passed."
end

# ╔═╡ ede7b3b1-5ec6-4abe-95c2-72b68552695a
md"""
Each `Tablet` accumulates its total rotation in its `accumulated_rotation` field.
Given a tablet's current rotation, we sometimes need to know which warp thread is
where or which edge of the card faces the shed.
"""

# ╔═╡ e275a226-c404-4e8b-a9de-2b126da4b452
#=
let
	t = Tablet(; a=:A, b=:B, c=:C, d=:D)
	@assert threads(t) == [:A, :B, :C, :D]
	t.accumulated_rotation = 1
	@assert threads(t) == [:D, :A, :B, :C]
	html"threads() assertions passed."
end
=#

# ╔═╡ f7e02d45-6de4-408c-99a0-ecaa274c6f39
"""
    top_edge(::Tablet)::TabletEdge

Return the TabletEdge of the top edge of the tablet.
This edge is easier to see on the loom than the shed edge
It is also unaffected by the tablet's `stacking`.
"""
function top_edge(t::Tablet)::TabletEdge
	# t.stacking affects which edge faces the shed but not which is on top
	# since changing t.stacking can only be done by flipping the card on its
	# vertical axis.
	r = mod(t.accumulated_rotation, 4)
	if r == 0 TabletEdge(1)
	elseif r == 1 TabletEdge(4)
	elseif r == 2 TabletEdge(3)
	else TabletEdge(2)
	end
end

# ╔═╡ ea0b660e-9512-4ad1-b99a-e17753f47d74
"""
    shot!(::Tablet)

Apply the current rotation to the tablet and return the colors of the warp
threads passing over the top and bottom of the fabric, and the crossing
direction (as a forward or backslash character) when looking at that face
of the fabric.
"""
function shot!(t::Tablet)
	@assert(abs(t.this_shot_rotation) == 1,
		"in shot!, this_shot_rotation = $(t.this_shot_rotation)")
	te = top_edge(t)
	be = opposite(te)
	t.accumulated_rotation += t.this_shot_rotation
	t.min_rotation = min(t.min_rotation, t.accumulated_rotation)
	t.max_rotation = min(t.max_rotation, t.accumulated_rotation)
	hole = if t.this_shot_rotation > 0
		if t.threading isa BackToFront
			stitchslant = '/'
		else
			stitchslant = '\\'
		end
		previous_hole
	else
		if t.threading isa BackToFront
			stitchslant = '\\'
		else
			stitchslant = '/'
		end
		next_hole
	end
	t.this_shot_rotation = 0
	wc(edge) = warp_color(t, hole(edge))
	return wc(te), wc(be), stitchslant
end

# ╔═╡ 776e4a65-62f7-4201-b8e5-6d5326e653fa
md"""
For a given `Tablet`, if `a` and `b` are one color and `c` and `d` are another,
then we can rotate the tablet in one direction to change colors and the other
to keep the color the same.  We can't control the slant of the stitch though.
"""

# ╔═╡ 98bb29dc-55e7-4f42-8456-d72079801a3a
begin
	stablets = [Tablet(; id = i, threading=BackToFront(),
				       a=COLORS[3], b=COLORS[3], c=COLORS[2], d=COLORS[2],
				       accumulated_rotation = i - 1)
		for i in 1:8
	]
	ztablets = [Tablet(; id = i, threading=FrontToBack(),
			           a=COLORS[3], b=COLORS[3], c=COLORS[2], d=COLORS[2],
		               accumulated_rotation = i - 1)
		for i in 1:8
	]
	stablets, ztablets
end

# ╔═╡ c6a06609-bf84-45cb-a837-68760b826cb3
md"""
### Tablet Charts
"""

# ╔═╡ a24eae67-f116-4c75-8fda-b942dab326c7
"""
    csscolor(color)
return (as a string) the CSS representation of the color.
"""
function csscolor end

# ╔═╡ 3c10060e-f2e1-4a05-8322-65009f5ef14e
begin
	function csscolor(color::RGB)
		css(x) = Int(round(x * 255))
		"rgb($(css(color.r)), $(css(color.g)), $(css(color.b)))"
	end

	csscolor(color::Colorant) =	"#$(hex(color))"
end

# ╔═╡ c4804cf2-85ba-4895-8404-47560df04e2f
function chart_tablet(tablet::Tablet; size=5, x=0)
    @assert tablet.accumulated_rotation == 0
    @assert tablet.this_shot_rotation == 0
    function swatch(i, c)
        elt("rect",
            :width => "$(size)mm",
            :height => "$(size)mm",
            :x => "$(x)mm",
            :y => "$(i * size)mm",
            :fill =>"$(csscolor(c))",
            :stroke => "gray")
    end
    function threading(th)
        x1 = x
        x2 = x1 + size
        y1 = 4 * size
        y2 = 5 * size
        # The direction that the thread passed through the card if the card
        # is facing to the right (FrontToTheRight stacking)
        if th isa BackToFront
            elt("line",
                :stroke => "gray",
                :strokeWidth =>"3px",
                :x1 => "$(x1)mm",
                :y1 => "$(y1)mm",
                :x2 => "$(x2)mm",
                :y2 => "$(y2)mm")
        else
            elt("line",
                :stroke => "gray",
                :strokeWidth => "5px",
                :x1 => "$(x2)mm",
                :y1 => "$(y1)mm",
                :x2 => "$(x1)mm",
                :y2 => "$(y2)mm" )
        end
    end
    elt("svg", :xmlns => "http://www.w3.org/2000/svg",
        elt("g",
            swatch(0, tablet.a), swatch(1, tablet.b),
            swatch(2, tablet.c), swatch(3, tablet.d),
            threading(tablet.threading)))
end

# ╔═╡ fd40ecf7-83cb-43b5-b87c-8273f8fd32c4
HTML(string((chart_tablet(
    Tablet{Color}(;
                  a=RGB(1, 0, 0),
                  b=RGB(0, 1, 0),
                  c=RGB(0, 0,1),
                  d=RGB(0.5, 0.5, 0.5));
    x=10))))

# ╔═╡ 22c96c85-2344-46bc-a64c-460414575677
function chart_tablets(tablets::Vector{<:Tablet})
    size = 5
    elt("svg",
	:xmlns => "http://www.w3.org/2000/svg",
	:width => "95%",
	# :viewBox => "0 0 $(length(tablets) * size) $(5 * size)",
	[ chart_tablet(tablet; size=size, x=size*(i-1))
	  for (i, tablet) in enumerate(tablets) ]...)
end

# ╔═╡ 418c2904-d16a-4c2d-a02f-c069918dca4c
md"""
## Stitches

How do we render stitches so we can see how our pattern might come out.
"""

# ╔═╡ abacffda-7c76-46cc-8e3c-e305a81b5702
"""
	stitch_image(length, width, direction)
Make a length by width Bool array that will be used to draw a stitch after
colored by `color_stitch`.

`direction` should be 1 or -1 to indicate slant direction.
"""
function stitch_image(length::Int, width::Int, direction::Int)
	@assert abs(direction) == 1
	stitch = zeros(Bool, length, width)
	slope = direction * (length) / (width)
	yIntercept = if direction == 1 0 else length end
	for l in 1 : length
		w = Int(round((l - yIntercept) / slope))
		if w < 1 w = 1 end
		if w > width w=width end
		stitch[l, w] = 1
	end
	for w in 1 : width
		l = Int(round(slope * w + yIntercept))
		if l < 1 l = 1 end
		if l > length l = length end
		stitch[l, w] = 1
	end
	stitch
end

# ╔═╡ ca9cae4a-f74b-46e7-9a24-fc8df3958a0f
stitch_image(length, width, direction::Char) =
	stitch_image(length, width,
		# Note that the Y axis is flipped.  Lower Y coordinates are closer to
		# the top of the display.
		direction == '/' ? -1 : 1)

# ╔═╡ 4ace6327-de0b-43fa-9b42-33661152de49
[ stitch_image(8, 4, 1), stitch_image(8, 4, -1) ]

# ╔═╡ 326c169a-2386-4e5d-97eb-3f6b6f691b9f
"""
    color_stitch(stitch_image, foreground::Color, background::Color)

Return a `Matrix` of `Color` with the same dimensions as stitch_image (which
should have been constructed by `stitch_image`).
"""
color_stitch(stitch::Matrix{Bool}, foreground::Color, background::Color) =
	map(stitch) do bit
		if bit
			foreground
		else
			background
		end
	end

# ╔═╡ 4853d329-c7e4-4a98-b057-4192513b0220
map([ stitch_image(8, 4, '/'), stitch_image(8, 4, '\\') ]) do i
	color_stitch(i, RGB(0, 1, 0), Gray(0.4))
	end

# ╔═╡ 8aa9c975-ff50-4db0-9939-7fee0cada96a
md"""
## Try Rendering a Proven Pattern

I'm new to tablet weaving.

To test the code above, we try constructing and rendering a simple pattern.  I found this one
["Simple Diamonds.. or Chevrons"](https://www.pinterest.com/pin/363525001170926977/)
and will try to implement/replicate it here.
"""

# ╔═╡ c3d99a5c-9c4c-4aff-b932-2dcc45a392ce
function make_chevron_tablets()
	foreground = RGB(map(x -> x/255, Colors.color_names["yellow3"])...)
	border = Gray(1)
	background = Gray(0)
	id = 0
	function tab(a, b, c, d, threading)
		id += 1
		Tablet{Color}(; id=id, a=a, b=b, c=c, d=d, threading=threading)
	end
	s = threading_for_char('s')
	z = threading_for_char('z')
	[
		# Border:
		tab(background, background, background, background, z),
		tab(border, border, border, border, z),
		tab(background, background, background, background, s),
		# Pattern:
		tab(background, background, background, foreground, s),
		tab(background, background, foreground, background, s),
		tab(background, foreground, background, background, s),
		tab(foreground, background, background, background, s),
		# Middle.
		tab(foreground, background, background, background, z),
		tab(background, foreground, background, background, z),
		tab(background, background, foreground, background, z),
		tab(background, background, background, foreground, z),
		# Border:
		tab(background, background, background, background, z),
		tab(border, border, border, border, s),
		tab(background, background, background, background, s)
	]
end

# ╔═╡ c4ab1370-cc66-4b54-901f-1c2680c01bf7
make_chevron_tablets()

# ╔═╡ f3d5b031-748c-414b-b8a7-201039aa3ae5
HTML(string(chart_tablets(make_chevron_tablets())))

# ╔═╡ 38e5dcdb-e192-4c89-9e49-c8a5ad2fcb3c
"""
    simple_rotation_plan(row_count::Int, rotation_direction::RotationDirection)

return a simple rotation plan function, as could be passed to `tablet_weaving`.
"""
function simple_rotation_plan(row_count::Int, rotation_direction::RotationDirection)
	function plan(tablets::Vector{<:Tablet}, row_number::Int, tablet_number::Int)
		if row_number <= row_count
			return rotation_direction
		else
			return nothing
		end
	end
end

# ╔═╡ cacc40ec-08f8-4b92-ac40-e1496ccd9410
"""
	tablet_weave(tablets::Vector{<:Tablet}, rotation_plan)

Simulate the weaving of and item that is warped according to `tablets` and is
woken according to `rotation_plan`.

`rotation_plan` is a function of three arguments:

* a vector of the tablets;

* the row number of the warp being formed;

* the number of the tablet, counted from the weaver's left.

It should return a RotationDirection.

`tablet_weave` rotates the tablets according to the plan function, steping the
row number until `rotation_plan` returns `nothing`.

`tablet_weave` returns several values:

* an array of the stitch color and slant, from which an image of the top face of the result can be made;

* the same, but for the bottom face of the result;

* a vector with one element per weft row, each element of which is a vector with
one element per tablet, giving the rotation that was applied to that tablet and its new top edge after applying that rotation, as a tuple.

"""
function tablet_weave(tablets::Vector{<:Tablet}, rotation_plan)
	tapestry_top = []
	tapestry_bottom = []
	instructions = []
	row = 1
	while true
		rotations = []
		for column in 1 : length(tablets)
			rot = rotation_plan(tablets, row, column)
			if rot == nothing
				@goto done
			end
			rotate!(tablets[column], rot)
			push!(rotations, rot)
		end
		weave = shot!.(tablets)
		push!(tapestry_top, map(weave) do (top, bottom, slant)
			(top, slant)
		end)
		push!(tapestry_bottom, map(weave) do (top, bottom, slant)
			(bottom, slant)
		end)
		push!(instructions, collect(zip(rotations, top_edge.(tablets))))
		row += 1
	end
	@label done
	return tapestry_top, tapestry_bottom, instructions
end

# ╔═╡ 517d7d7a-c31d-4917-8db9-ff7eb68e1bd5
"""
	weaving_image(face; stitchlength = 5, stitchwidth = 3, blank = Gray(0.25))

Return an image array derived from `face`. which is as would be returned as the
first or second return value of `tablet_weave`.
"""
function weaving_image(face;
		stitchlength = 5, stitchwidth = 3, blank = Gray(0.25))
	vcat(map(face) do row
		hcat(map(row) do w
			color, slant = w
			color_stitch(stitch_image(stitchlength, stitchwidth, slant),
						 color, blank)
		end...)
	end)
end

# ╔═╡ 454626a9-f96b-4d2d-adff-1cc24e2b423f
let
	top, bottom, instructions =
		tablet_weave(make_chevron_tablets(), simple_rotation_plan(16, Forward()))
	weaving_image(top), weaving_image(bottom)
end

# ╔═╡ eef97e76-284b-456f-9ad8-9b86d87d6954
# Lets try a different pottern, from http://research.fibergeek.com/2002/10/10/first-tablet-weaving-double-diamonds/
function make_diamond_tablets()
	f = Gray(0.2)
	b = Gray(0.8)
	id = 0
	function tab(a, b, c, d, threading)
		id += 1
		Tablet{Color}(; id=id, a=a, b=b, c=c, d=d, threading=threading)
	end
	s = threading_for_char('s')
	z = threading_for_char('z')
	[
		# Border:
		tab(b, b, b, b, z),   #  1
		tab(b, b, b, b, z),   #  2
		tab(f, f, f, f, z),   #  3
		# Pattern:
		tab(b, f, f, b, s),   #  4
		tab(f, f, b, b, s),   #  5
		tab(f, b, b, f, s),   #  6
		tab(b, b, f, f, s),   #  7
		tab(b, f, f, b, s),   #  8
		tab(f, f, b, b, s),   #  9
		tab(f, b, b, f, s),   # 10
		tab(b, b, f, f, s),   # 11
		# Reverse:
		tab(b, b, f, f, z),   # 12
		tab(f, b, b, f, z),   # 13
		tab(f, f, b, b, z),   # 14
		tab(b, f, f, b, z),   # 15
		tab(b, b, f, f, z),   # 16
		tab(f, b, b, f, z),   # 17
		tab(f, f, b, b, z),   # 18
		tab(b, f, f, b, z),   # 19
		# Enough!
		# border
		tab(f, f, f, f, s),   # 20
		tab(b, b, b, b, s),   # 21
		tab(b, b, b, b, s)	  # 22
	]
end

# ╔═╡ ed3bc04e-1178-4c04-9d35-3471f7b89c88
length(make_diamond_tablets())

# ╔═╡ fd07c1d6-808e-4573-8ff9-e47b0ee68756
HTML(string(chart_tablets(make_diamond_tablets())))

# ╔═╡ 93497aa8-ba19-45fe-a596-dd5ef194229f
let
	top, bottom, instructions =
		tablet_weave(make_diamond_tablets(), simple_rotation_plan(16, Forward()))
	weaving_image(top), weaving_image(bottom)
end

# ╔═╡ ee85e6c6-2ade-4178-8850-55e776916ac1
md"""
## How to Describe Tablet Motion During Weaving

After each throw, each tablet must be rotated **forward** or **backward** to make
a new shed.  In the simplest patterns, all tablets are rotated in the same
direction.  For our gray code pattern however, tablets move in different
directions for each shed.  How can we represent these rotations for ease of
execution by the weaver?

There is one set of tablet motions for each throw of the shuttle.  We should have
a row number.  The weaver must keep track of which row they're working.

There is motion for each tablet.  The motion of a single tablet can be concisely
described by unicode arrows (🡑, 🡓) or by the edge number of the tablet that is
facing the shed or on top.  The latter is less error prone since an incorrect
starting position for a tablet will be detected.

The simplest representation is a `Vector` for the whole pattern.
Each element would be a `Vector` of digits from `1` to `4` indicating the edge
of the tablet that's currently "on top".
"""

# ╔═╡ 910c1e57-f7f0-4cb9-aa6c-826ff71e7b3a
md"""
## Generating a Pattern

We have an array of the "image" we want to weave.  How do we translate that into
a set of tablets, their warping, and their motions?

How do we execute that "plan" to produce a stitch image to see how the pattern
turned out.

For a two color pattern, we can warp each tablet with one color in holes **A**
and **C** and the other in holes **B** and **D**.  Whatever the previous stitch,
the tablet can be rotated to either color.  The slant of the stitch can't be
controlled though.
"""

# ╔═╡ 6dc90672-f80e-4e2c-9689-7e777b03ff8d
"""
    tablets_for_image(image)

Return a `Vector` of the `Tablet`s that could be used to weave the image, which should
be a two dimensional array.  If the tablets can't be determined then an error is
thrown.
The first dimension of `image` counts rows of weft.  The second dimension counts
columns of warp, and therefore, tablets.
"""
function tablets_for_image(image)
	@assert length(size(image)) == 2
	cardcount = size(image)[2]
	throwcount = size(image)[1]
	@assert cardcount < throwcount
	# The possible colors for each "column" of warp:
	colors = [OrderedSet{Color}() for i in 1:cardcount]
	for rownum in 1:throwcount
		for cardnum in 1:cardcount
			push!(colors[cardnum], image[rownum, cardnum])
		end
	end
	@assert all(x -> x > 0 && x <= 2, map(length, colors))
	map(colors) do c
		if length(c) == 1
			Tablet(a = c[1], b = c[1], c = c[1], d = c[1])
		else
			Tablet(a = c[1], b = c[2], c = c[1], d = c[2])
		end
	end
end

# ╔═╡ 4bd5b024-9be5-42f3-999b-6d9300003dd9
tablets_for_image(longer_dimension_counts_weft(GRAY_WEAVE))

# ╔═╡ 24a0fb03-3cf5-46a2-83bc-92e2607a9216
md"""
`tablets_for_image` does nothing about tablet threading, only colors.

The tablet weaving patterns I've been all seem to have one threading on one
side of the pattern and another threading on the other side, with the
possible exception of the borders having different threading from the field.

We can introduce a function that sets one threading from the edge to the middle
and switches to the other threading for the other half.
"""

# ╔═╡ f1f10056-0810-47cf-919b-b6aa93b361e0
function symetric_threading!(tablets::Vector{<:Tablet};
							 leftthreading::TabletThreading = BackToFront())
	l = length(tablets)
	middle = floor(Int, l / 2)
	for i in 1 : middle
		left = tablets[i]
		right = tablets[l + 1 - i]
		left.threading = leftthreading
		right.threading = other(leftthreading)
	end
	tablets
end

# ╔═╡ 11ac0388-eadf-48c7-8ec9-2c4ce0f5169f
GRAY_TABLETS = let
	border_color = RGB(0.5, 0.5, 0.5)
	border1 = Tablet(
		a=border_color,
		b=border_color,
		c=border_color,
		d=border_color,
		threading=BackToFront())
	border2 = Tablet(
		a=border1.a,
		b=border1.b,
		c=border1.c,
		d=border1.d,
		threading=other(border1.threading))
	(2 * border1) +
		symetric_threading!(tablets_for_image(
			longer_dimension_counts_weft(GRAY_WEAVE));
					leftthreading=other(border1.threading)) +
		(2 * border2)
end

# ╔═╡ 2b6d73bc-dd88-4f4a-b739-58d57b189df6
HTML(string(chart_tablets(GRAY_TABLETS)))

# ╔═╡ 02798c2e-3d12-4eff-90f8-e24a631ad8f0
"""
	want_color(::Tablet, color)

return the new top edge if the tablet is rotated so that the stitch
will come out the specified color.  `want_color` is used to turn an
image into a weaving pattern.
"""
function want_color(tablet::Tablet{T}, color::T) where T
	e = top_edge(tablet)
	c_next = warp_color(tablet, next_hole(e))
	c_prev = warp_color(tablet, previous_hole(e))
	# If both colors are the same, which direction should we prefer?
	# Probably the one that is towards 0 accumulated twist.
	want_rotation =
		if c_next == c_prev
			- sign(tablet.accumulated_rotation)
		elseif color == c_next
			-1
		elseif color == c_prev
			1
		else
			error("Can't match color $c with tablet $tablet.")
		end
	if want_rotation == 0
		want_rotation = 1
	end
	new_edge = if want_rotation == 1
		previous(e)
	else
		next(e)
	end
	rot::RotationDirection = Forward()
	for r in [Forward(), Backward()]
		if rotation(tablet, r) == want_rotation
			rot = r
			break
		end
	end
	return new_edge, rot
end

# ╔═╡ 432d26a6-bac4-48b8-a0ab-1bb1c246d513
let
	tablet = GRAY_TABLETS[5]
	red = tablet.a
	yellow = tablet.b
	red, yellow #=
	@assert want_color(tablet, red) == (TabletEdge(4), Forward())
	@assert want_color(tablet, yellow) == (TabletEdge(2), Backward())
	html"want_color tests pass."
	=#
end

# ╔═╡ a38a5557-7a7d-49d3-8041-7a6d655e6a37
function pretty_stitches(image_stitches, flip_right_to_left::Bool)
    # image_stitches should be the top_image_stitches or bottom_image_stitches
    # of a TabletWeavingPattern.
    stitch_width = 2
    stitch_length = 3
    stitch_diameter = 1
    uses = []
    function use(row, col, color, slant)
        push!(uses,
              elt("use",
	          :href => slant == '/' ? "#stitch1" : "#stitch2",
	          :x => "$(col * stitch_width)",
	          :y => "$(row * stitch_length)",
	          :width => "$(stitch_width)",
	          :height => "$(stitch_length)",
	          :style => "stroke: none; fill: $(csscolor(color)); vector-effect: non-scaling-stroke"))
    end
    for (rownum, row) in enumerate(image_stitches)
	for (colnum, stitch) in enumerate(row)
	    (color, slant) = stitch
	    use(rownum, colnum, color, slant)
	end
    end
    println(length(uses))
    viewbox_width = stitch_width * length(image_stitches[1])
    viewbox_height = stitch_length * length(image_stitches)
    elt("svg", 
        :viewBox => "0 0 $viewbox_width $viewbox_height",
        elt("g",
   	    elt("symbol",
                :id => "stitch1",
    	        :preserveAspectRatio => "xMinYMin",
    	        :viewBox => "0 0 $(stitch_width) $(stitch_length)",
                :refX => "0",
                :refY => "0",
    	        svg_stitch(stitch_width, stitch_length, stitch_diameter, '/';),),
            elt("symbol",
                :id => "stitch2",
    	        :preserveAspectRatio => "xMinYMin",
    	        :viewBox => "0 0 $(stitch_width) $(stitch_length)",
    	        :refX => "0",
                :refY => "0",
    	        svg_stitch(stitch_width, stitch_length, stitch_diameter, '\\';),),
            uses...))
end

# ╔═╡ 89da550c-c4fb-4b31-8f28-1e4bbc707ec2
svg_stitch(5, 10, 1, '/';)

# ╔═╡ ad13c3e7-5102-4f7d-99d1-6deea22a2ec5
begin
	struct TabletWeavingPattern{C} # where C causes "invalid type signature" error
		title::AbstractString
		image::Array{C, 2}
		initial_tablets::Vector{<:Tablet{<:C}}
		weaving_steps
		end_tablets
		# top_image_stitches and bottom_image_stitches each are a vector
		# (one element per row) of vectors (one element per stitch) of the
		# stitch color and slant, from which an image of the top or bottom
		# face of the result can be made:
		top_image_stitches
		bottom_image_stitches
	end

	function rotation_plan_from_image(image, tablets)
		tablets = copy.(tablets)
		function plan(tablets, row, column)
			if row > size(image)[1]
				return nothing
			end
			color = image[row, column]
	    	(edge, rotation) = want_color(tablets[column], color)
	    	rotation
		end
		plan
	end
	
	function TabletWeavingPattern(title::AbstractString, image;
			threading_function = identity)
		image = longer_dimension_counts_weft(image)
		initial_tablets = threading_function(tablets_for_image(image))
		tablets = copy.(initial_tablets)
		top, bottom, instructions =
			tablet_weave(tablets, rotation_plan_from_image(image, tablets))
		
		TabletWeavingPattern(title, image, initial_tablets, instructions, tablets,
			top, bottom)
	end
end

# ╔═╡ 2f1e5906-300d-4c35-84a4-4b1ced9390b7
function pretty_plan(p::TabletWeavingPattern)
    summary(heading, reader) =
        elt("tr",
            elt("th", :align => "right", heading),
            map(p.end_tablets) do t
                elt("td", :align => "right", reader(t))
            end...)
    elt("table",
        # Each row of the plan
        [ elt("tr",
              elt("th", :align => "right", i),
              [ elt("td", :align => "right",
                    tablet_rotation_char(t[1]),
                    t[2].label)
                for t in step
                    ]...)
          for (i, step) in enumerate(p.weaving_steps)
              ]...,
        # End summary:
        summary("end", t -> t.accumulated_rotation),
        summary("min", t -> t.min_rotation),
        summary("max", t -> t.max_rotation))
end

# ╔═╡ 8d8e5ec7-3177-4e64-ab6d-791dbf0a06c4
function pretty(p::TabletWeavingPattern)
    elt("div",
	elt("h2", p.title),
	elt("div", chart_tablets(p.initial_tablets)),
	elt("div", pretty_plan(p)),
	elt("h3", "Front"),
	pretty_stitches(p.top_image_stitches, false),
	elt("h3", "Back"),
	pretty_stitches(p.bottom_image_stitches, true))
end

# ╔═╡ 4d45dbf1-41cf-4568-b099-789630effce3
tablets(p::TabletWeavingPattern) = copy.(p.initial_tablets)

# ╔═╡ bec2540b-b3e8-47a7-b968-769b8765d9ef
WOVEN_GRAY_PATTERN = TabletWeavingPattern("Gray Code Pattern", GRAY_WEAVE;
	threading_function = symetric_threading!)

# ╔═╡ 842b33c6-3ab2-461e-b8ad-f30f224a0d11
string(pretty_stitches(WOVEN_GRAY_PATTERN.top_image_stitches, false))

# ╔═╡ 9c8d2181-b183-40e5-b235-16a59727fda8
HTML(string(pretty(WOVEN_GRAY_PATTERN)))

# ╔═╡ 2247a5df-98f8-4d63-8443-2a1cb743aa8b
HTML(string(
let
    stitch_width = 5               # x direction
    stitch_length = 5 * sqrt(3)    # y direction
    center = [
        stitch_width / 2,
        stitch_length / 2
    ]
    stitch_radius =  stitch_width / 6    # arbitrary

    circle1_center = [
        stitch_radius,
        stitch_length - stitch_radius
    ]
    circle2_center = [
        stitch_width - stitch_radius,
        stitch_radius
    ]

    # we can translate the center of each circle by +/= the vector
    # perpendicular to this angle:
    diagonal = circle2_center - circle1_center
    trans = [ - diagonal[2], diagonal[1] ]    # perpendicular
    trans = trans / norm(trans)               # unit vector
    trans = trans * stitch_radius

    guide_style = join(
        [
            "stroke: blue",
            "stroke-width: 1px",
            "fill: none",
            "vector-effect: non-scaling-stroke"
        ], "; ")
    stitch_style = join(
        [
            "fill: none",
            "stroke: yellow",
            "stroke-width: 1px",
            "vector-effect: non-scaling-stroke"
        ], "; ")

    function line(p1, p2, style)
        elt("line",
            :x1 => p1[1],
            :y1 => p1[2],
            :x2 => p2[1],
            :y2 => p2[2],
            :style => style)
    end

    elt("svg",
        :xmlns => "http://www.w3.org/2000/svg",
        :viewBox =>"0 0 $(2 * stitch_width) $(2 * stitch_length)",
        :width => "50%",
        # bounding rectangle:
        elt("rect",
            :x => 0,
            :y => 0,
            :width => stitch_width,
            :height => stitch_length,
            :style => guide_style),
        # Diagonal:
        line(circle1_center, circle2_center, guide_style),
        # Normals:
        line(circle1_center, circle1_center + trans, guide_style),
        line(circle2_center, circle2_center + trans, guide_style),
        # circle1:
        elt("circle",
            :style => stitch_style,
            :r => stitch_radius,
            :cx => circle1_center[1],
            :cy => circle1_center[2]),
        # circle2:
        elt("circle",
            :style => stitch_style,
            :r => stitch_radius,
            :cx => circle2_center[1],
            :cy => circle2_center[2]),
        # lines:
        line(circle1_center + trans,
             circle2_center + trans,
             stitch_style),
        line(circle1_center - trans,
             circle2_center - trans,
             stitch_style))
end
))

# ╔═╡ 9cc8f230-1294-420f-a877-726931e7e79f
"""
    svg_stitch(stitch_width, stitch_length, stitch_diameter, slant::Char)

Generate the SVG for drawing a stitch.

`stitch_width` is the width of the stitch on the SVG X and weaving
weft axis.

`stitch_diameter` is how wide the stitch is.

`stitch_length` is the length of the stitch in the SVG Y and warp
axis.

`slant` is as returned by `shot!`.
   
"""
function svg_stitch(stitch_width, stitch_length, 
                    stitch_diameter, slant::Char;
                    show_guides = false)
    stitch_radius = stitch_diameter / 2
    circle1 = [
        stitch_radius,
        stitch_length - stitch_radius
    ]
    circle2 = [
        stitch_width - stitch_radius,
        stitch_radius
    ]
    if slant == '\\'
        # Swap X coordinates:
        (circle1[1], circle2[1]) = (circle2[1], circle1[1])
    end
    # we can translate the center of each circle by +/= the vector
    # perpendicular to this angle:
    diagonal = circle2 - circle1
    trans = [ - diagonal[2], diagonal[1] ]    # perpendicular
    trans = trans / norm(trans)               # unit vector
    trans = trans * stitch_radius

    guide_style = join(
        [
            "stroke: blue",
            "stroke-width: 1px",
            "fill: none",
            "vector-effect: non-scaling-stroke"
        ], "; ")
    stitch_style = join(
        [
            # "stroke: yellow",
            "stroke-width: 1px",
            "vector-effect: non-scaling-stroke"
        ], "; ")

    function line(p1, p2, style)
        elt("line",
            :x1 => p1[1],
            :y1 => p1[2],
            :x2 => p2[1],
            :y2 => p2[2],
            :style => style)
    end

    guides = []
    if show_guides
        push!(guides,
              # bounding rectangle:
              elt("rect",
                  :x => 0,
                  :y => 0,
                  :width => stitch_width,
                  :height => stitch_length,
                  :style => guide_style),
              # Diagonal:
              line(circle1, circle2, guide_style),
              # Normals:
              line(circle1, circle1 + trans, guide_style),
              line(circle2, circle2 + trans, guide_style))
    end
    p1 = circle1 + trans
    p2 = circle2 + trans
    p3 = circle2 - trans
    p4 = circle1 - trans
    pathpoint(p) = join(string.(p), " ")

    elt("g",
        # viewBox="0 0 $(2 * stitch_width) $(2 * stitch_length)",
        # width="50%",
        guides...,
        elt("path",
            :style => stitch_style,
            :d => join([
                "M $(pathpoint(p1))",
                "L $(pathpoint(p2))",
                let
                    r = stitch_radius
                    "A $r $r 0 0 0 $(pathpoint(p3))"
                end,
                "L $(pathpoint(p4))",
                let
                    r = stitch_radius
                    "A $r $r 0 0 0 $(pathpoint(p1))"
                end,
            ], " ")))
end


# ╔═╡ abb9e8cd-564e-4fef-afd4-7f05eb76a944
HTML(string(
    let
        stitch_width = 1
        stitch_height = 1

        use(id, color, x, y) =
            elt("use",
                :href => "#$id",
                :x => "$(x * stitch_width)mm",
                :y => "$(y * stitch_height)mm",
                :width => "$(stitch_width)mm",
                :height => "$(stitch_height)mm",
                :style => "stroke: none; fill: $color; vector-effect: non-scaling-stroke")

        elt("svg",
            :xmlns => "http://www.w3.org/2000/svg",
            :width => "50%",
            :viewBox => "0 0 100 100",

            elt("symbol",
                :id => "stitch1",
                :preserveAspectRatio => "xMinYMin",
                :viewBox => "0 0 $stitch_width $stitch_height",
                :refX => "0",
                :refY =>" 0",
                svg_stitch(stitch_width, stitch_height, 1, '/';)),
            elt("symbol",
                :id => "stitch2",
                :preserveAspectRatio => "xMinYMin",
                :viewBox => "0 0 $stitch_width $stitch_height",
                :refX => "0",
                :refY =>"0",
                svg_stitch(stitch_width, stitch_height, 1, '\\';)),

            use("stitch1", "yellow", 0, 0),
            use("stitch1", "blue",   1, 0),
            use("stitch2", "yellow", 2, 0),
            use("stitch2", "blue",   3, 0),
            use("stitch1", "blue",   0, 1),
            use("stitch1", "yellow", 1, 1),
            use("stitch2", "blue",   2, 1),
            use("stitch2", "yellow", 3, 1)
            )
    end
))


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
OrderedCollections = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
Pluto = "c3e4b0f8-55cb-11ea-2926-15256bba5781"
XML = "72c71f33-b9b6-44de-8c94-c961784809e2"

[compat]
Colors = "~0.12.8"
OrderedCollections = "~1.4.1"
Pluto = "~0.19.14"
XML = "~0.1.3"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "d6e0e330e038d0ca613e56390dea1aea1f731742"

[[deps.AbstractTrees]]
git-tree-sha1 = "5c0b629df8a5566a06f5fef5100b53ea56e465a0"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "84259bb6172806304b9101094a7cc4bc6f56dbc6"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.5"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.Configurations]]
deps = ["ExproniconLite", "OrderedCollections", "TOML"]
git-tree-sha1 = "62a7c76dbad02fdfdaa53608104edf760938c4ca"
uuid = "5218b696-f38b-4ac9-8b61-a12ec717816d"
version = "0.17.4"

[[deps.DataAPI]]
git-tree-sha1 = "46d2680e618f8abd007bce0c3026cb0c4a8f2032"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.12.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExproniconLite]]
git-tree-sha1 = "09dcb4512e103b2b8ad45aa35199633797654f47"
uuid = "55351af7-c7e9-48d6-89ff-24e801d99491"
version = "0.7.1"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.FuzzyCompletions]]
deps = ["REPL"]
git-tree-sha1 = "e16dd964b4dfaebcded16b2af32f05e235b354be"
uuid = "fb4132e2-a121-4a70-b8a1-d5b831dcdcc2"
version = "0.5.1"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "IniFile", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "a97d47758e933cd5fe5ea181d178936a9fc60427"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.5.1"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.LazilyInitializedFields]]
git-tree-sha1 = "eecfbe1bd3f377b7e6caa378392eeed1616c6820"
uuid = "0e77f7df-68c5-4e49-93ce-4cd80f5598bf"
version = "1.2.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "5d4d2d9904227b8bd66386c1138cf4d5ffa826bf"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "0.4.9"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.MsgPack]]
deps = ["Serialization"]
git-tree-sha1 = "a8cbf066b54d793b9a48c5daa5d586cf2b5bd43d"
uuid = "99f44e22-a591-53d1-9472-aa23ef4bd671"
version = "1.1.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "3c3c4a401d267b04942545b1e964a20279587fd7"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.3.0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e60321e3f2616584ff98f0a4f18d98ae6f89bbb3"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.17+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.Pluto]]
deps = ["Base64", "Configurations", "Dates", "Distributed", "FileWatching", "FuzzyCompletions", "HTTP", "HypertextLiteral", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "MsgPack", "Pkg", "PrecompileSignatures", "REPL", "RegistryInstances", "RelocatableFolders", "Sockets", "TOML", "Tables", "URIs", "UUIDs"]
git-tree-sha1 = "c3f344a915bc1d67455ecc5e38f4a184ffc4ad96"
uuid = "c3e4b0f8-55cb-11ea-2926-15256bba5781"
version = "0.19.14"

[[deps.PrecompileSignatures]]
git-tree-sha1 = "18ef344185f25ee9d51d80e179f8dad33dc48eb1"
uuid = "91cefc8d-f054-46dc-8f8c-26e11d7c5411"
version = "3.0.3"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegistryInstances]]
deps = ["LazilyInitializedFields", "Pkg", "TOML", "Tar"]
git-tree-sha1 = "ffd19052caf598b8653b99404058fce14828be51"
uuid = "2792f1a3-b283-48e8-9a74-f99dce5104f3"
version = "0.1.0"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "22c5201127d7b243b9ee1de3b43c408879dff60f"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "c79322d36826aa2f4fd8ecfa96ddb47b174ac78d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "8a75929dcd3c38611db2f8d08546decb514fcadf"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.9"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "e59ecc5a41b000fa94423a578d29290c7266fc10"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.XML]]
deps = ["AbstractTrees", "Dates", "Downloads", "OrderedCollections"]
git-tree-sha1 = "8ec5c77816d33e98c59019ed14f92211b3ab786f"
uuid = "72c71f33-b9b6-44de-8c94-c961784809e2"
version = "0.1.3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╠═c1d9224b-7b60-451c-8889-11f00833f1c2
# ╟─89e97690-18a6-11ed-15e4-4bb0cd5b7c50
# ╠═9c0b434e-571c-4181-9350-848d50ba42e9
# ╠═581fda2d-0771-4283-8ca1-4b88cbeffecf
# ╠═0baa4c77-bf7a-4d39-b964-d4636975f8fa
# ╟─590963b9-bd0f-4c32-a778-873d22ec9c0f
# ╠═a3b3c00d-425d-4437-b964-50946b7e75b3
# ╠═e147b976-9227-4d54-8b14-f05d8eb0d42e
# ╠═fcb7d96f-f2ce-44cb-ac86-3ef6a6195bf4
# ╠═b04d2b69-aa8a-4174-8ef8-3e6b797354e7
# ╠═c2b1f51e-77fb-4e23-94cc-699c124b81c3
# ╠═78e317ca-d347-45a9-9058-b2e7b187c843
# ╟─1cf1cf59-d324-447a-8a72-b393c96b549f
# ╠═47320875-bad1-4528-8f78-82b017deedab
# ╠═8b85264e-25c8-4ae3-a952-ee30d622f918
# ╟─68c32382-4511-4345-a523-d9854b91e754
# ╠═786f8502-a081-4baf-b82d-a936cdfaae5e
# ╠═6d65f0b3-7370-4a7d-82bc-607f8b0f8c8c
# ╠═b12c2fe2-a32e-4e6f-a7d7-cfc24e8cb00c
# ╠═0fea18b7-b40e-4ca5-95e5-744e619ea14a
# ╠═61de53db-f01d-4294-8baf-d570abcd8d15
# ╠═a5796f2d-3754-4d99-9a37-2b476cc4f5a2
# ╟─31bdd4ca-aa24-4600-9a72-36410636019b
# ╠═bf12e28b-6bd1-45e3-9cea-e81d412c0097
# ╟─40bd184d-3332-49c0-a349-64b4e5fcc4aa
# ╟─56453fbd-6f6a-4c11-b2ba-acae84b66f48
# ╟─86033a92-cd04-4c52-845d-89a8a473506c
# ╟─f1c8a4c6-6c22-49f4-9df1-ef3ae5e3cb40
# ╟─50e521b5-c4f7-464d-b6dd-5c7f9d5b4bd0
# ╟─bb8a5f20-62af-4f28-b0df-85af57beb8f3
# ╟─9d85d3ef-847b-405c-817b-71097b56fee5
# ╟─b3ec1ee7-77d8-417a-834a-70c6c6608ae7
# ╟─748199f2-e5d8-4272-9120-f8b50264b5d6
# ╟─e31dd514-64af-4491-aac2-b47a85372650
# ╟─b38913ac-f91f-4e6d-a95a-506b8d3c754c
# ╟─8eea1d46-ca5b-48d4-9829-bce769dfcfbb
# ╟─f3a1f857-0d6c-4f29-8095-4c6f189b3604
# ╟─82725eaa-1605-4471-a808-360d0693dd43
# ╟─71e0104b-beb4-4e3e-8def-218f88fdfbcd
# ╟─b901fcdd-31dc-4643-9dba-21e70207141b
# ╟─30c08bee-e3f9-4672-a4d6-29df3ba8a6e5
# ╟─5498ffbc-40f9-44dd-9b6a-484e2498c406
# ╟─6d796003-f336-44ed-8831-8ea2b56fe865
# ╠═1b7b4e33-97c3-4da6-ad86-b9b4646dc619
# ╟─b396b71e-8510-4f7c-9017-50693b2f9c1d
# ╟─ede7b3b1-5ec6-4abe-95c2-72b68552695a
# ╟─e275a226-c404-4e8b-a9de-2b126da4b452
# ╠═f7e02d45-6de4-408c-99a0-ecaa274c6f39
# ╟─ea0b660e-9512-4ad1-b99a-e17753f47d74
# ╟─776e4a65-62f7-4201-b8e5-6d5326e653fa
# ╠═98bb29dc-55e7-4f42-8456-d72079801a3a
# ╟─c6a06609-bf84-45cb-a837-68760b826cb3
# ╟─a24eae67-f116-4c75-8fda-b942dab326c7
# ╠═3c10060e-f2e1-4a05-8322-65009f5ef14e
# ╠═c4804cf2-85ba-4895-8404-47560df04e2f
# ╟─fd40ecf7-83cb-43b5-b87c-8273f8fd32c4
# ╠═22c96c85-2344-46bc-a64c-460414575677
# ╠═418c2904-d16a-4c2d-a02f-c069918dca4c
# ╠═abacffda-7c76-46cc-8e3c-e305a81b5702
# ╠═ca9cae4a-f74b-46e7-9a24-fc8df3958a0f
# ╠═4ace6327-de0b-43fa-9b42-33661152de49
# ╟─326c169a-2386-4e5d-97eb-3f6b6f691b9f
# ╠═4853d329-c7e4-4a98-b057-4192513b0220
# ╟─8aa9c975-ff50-4db0-9939-7fee0cada96a
# ╠═c3d99a5c-9c4c-4aff-b932-2dcc45a392ce
# ╠═c4ab1370-cc66-4b54-901f-1c2680c01bf7
# ╠═f3d5b031-748c-414b-b8a7-201039aa3ae5
# ╟─38e5dcdb-e192-4c89-9e49-c8a5ad2fcb3c
# ╠═cacc40ec-08f8-4b92-ac40-e1496ccd9410
# ╟─517d7d7a-c31d-4917-8db9-ff7eb68e1bd5
# ╠═454626a9-f96b-4d2d-adff-1cc24e2b423f
# ╠═eef97e76-284b-456f-9ad8-9b86d87d6954
# ╠═ed3bc04e-1178-4c04-9d35-3471f7b89c88
# ╠═fd07c1d6-808e-4573-8ff9-e47b0ee68756
# ╠═93497aa8-ba19-45fe-a596-dd5ef194229f
# ╟─ee85e6c6-2ade-4178-8850-55e776916ac1
# ╟─910c1e57-f7f0-4cb9-aa6c-826ff71e7b3a
# ╠═6dc90672-f80e-4e2c-9689-7e777b03ff8d
# ╠═4bd5b024-9be5-42f3-999b-6d9300003dd9
# ╟─24a0fb03-3cf5-46a2-83bc-92e2607a9216
# ╠═f1f10056-0810-47cf-919b-b6aa93b361e0
# ╠═11ac0388-eadf-48c7-8ec9-2c4ce0f5169f
# ╠═2b6d73bc-dd88-4f4a-b739-58d57b189df6
# ╟─02798c2e-3d12-4eff-90f8-e24a631ad8f0
# ╠═432d26a6-bac4-48b8-a0ab-1bb1c246d513
# ╠═8d8e5ec7-3177-4e64-ab6d-791dbf0a06c4
# ╠═2f1e5906-300d-4c35-84a4-4b1ced9390b7
# ╠═a38a5557-7a7d-49d3-8041-7a6d655e6a37
# ╠═89da550c-c4fb-4b31-8f28-1e4bbc707ec2
# ╠═ad13c3e7-5102-4f7d-99d1-6deea22a2ec5
# ╠═4d45dbf1-41cf-4568-b099-789630effce3
# ╠═bec2540b-b3e8-47a7-b968-769b8765d9ef
# ╠═842b33c6-3ab2-461e-b8ad-f30f224a0d11
# ╠═9c8d2181-b183-40e5-b235-16a59727fda8
# ╠═2247a5df-98f8-4d63-8443-2a1cb743aa8b
# ╠═9cc8f230-1294-420f-a877-726931e7e79f
# ╠═abb9e8cd-564e-4fef-afd4-7f05eb76a944
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
