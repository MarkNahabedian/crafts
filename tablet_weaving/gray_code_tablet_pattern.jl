### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 9c0b434e-571c-4181-9350-848d50ba42e9
begin
	using Base: @kwdef
	using Colors
	using Markdown
	using Hyperscript
	using OrderedCollections
end

# ╔═╡ 89e97690-18a6-11ed-15e4-4bb0cd5b7c50
md"""
# Gray Code Tablet Weaving Pattern
"""

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

	threading_char(::BackToFront) = '/'
	threading_char(::BackToFront) = '\\'
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
end

# ╔═╡ 31bdd4ca-aa24-4600-9a72-36410636019b
md"""
We use a `Vector` of `Tablet`s to describe how the loom is set up for
weaving.  for convenience, we can add these vectors together for a
wider pattern.  We can also multiply them to repeat tablets.
"""

# ╔═╡ bf12e28b-6bd1-45e3-9cea-e81d412c0097
begin
    function (Base.:+)(a::Tablet{T}, b::Tablet{T})::Vector{Tablet{T}} where T
        [a, b]
    end

    function (Base.:+)(a::Tablet{T}, v::Vector{Tablet{T}})::Vector{Tablet{T}} where T
        [a, v...]
    end

    function (Base.:+)(v::Vector{Tablet{T}}, b::Tablet{T})::Vector{Tablet{T}} where T
	[v..., b]
    end

    function (Base.:+)(v1::Vector{Tablet{T}}, 
                       v2::Vector{Tablet{T}})::Vector{Tablet{T}} where T
		[v1..., v2...]
    end

    function (Base.:*)(repeat::Int, t::Tablet{T})::Vector{Tablet{T}} where T
		result = Vector{Tablet{T}}()
		for i in 1:repeat
		    push!(result, t)
		end
		result
    end

    function (Base.:*)(repeat::Int, v::Vector{Tablet{T}})::Vector{Tablet{T}} where T
		result = Vector{Tablet{T}}()
		for i in 1:repeat
		    append!(result, v)
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

# ╔═╡ b38913ac-f91f-4e6d-a95a-506b8d3c754c
"""
The `Clockwise` direction refers to how the tablet would move if it were facing
the weaver.  Whether this results in ABCD or DCBA rotation depends on how the
card is threaded since that determines Whether the front or the back of the
tablet is facing the weaver.
"""
struct Clockwise <: RotationDirection end

# ╔═╡ 8eea1d46-ca5b-48d4-9829-bce769dfcfbb
function rotation(t::Tablet, ::Clockwise)
	if isa(t.threading, BackToFront)
		rotation(t, ABCD())
	else
		rotation(t, DCBA())
	end
end

# ╔═╡ f3a1f857-0d6c-4f29-8095-4c6f189b3604
"""
The `CounterClockwise` direction refers to how the tablet would move if it were facing
the weaver.  Whether the front or the back of the tablet is facing the weaver
depends on whether the card is `BackToFront` or `FrontToBack` threaded.
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

# ╔═╡ b901fcdd-31dc-4643-9dba-21e70207141b
"""
The Forward rotation moves the top corner of the tablet closest to the
weaver and the cloth beam to be the bottom corner closest to the weaver.
"""
struct Forward <: RotationDirection end

# ╔═╡ 30c08bee-e3f9-4672-a4d6-29df3ba8a6e5
function rotation(t::Tablet, ::Forward)
	if isa(t.stacking, FrontToTheRight)
		rotation(t, Clockwise())
	else
		rotation(t, CounterClockwise())
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
		rotation(t, Clockwise())
	else
		rotation(t, CounterClockwise())
	end
end

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

# ╔═╡ e31dd514-64af-4491-aac2-b47a85372650
let
	bf = Tablet(; a=:A, b=:B, c=:C, d=:D, threading=BackToFront())
	rotate!(bf, ABCD())
	@assert bf.this_shot_rotation == 1
	rotate!(bf, DCBA())
	@assert bf.this_shot_rotation == 0
	html"ABCD and DCBA assertions passed."
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

# ╔═╡ b396b71e-8510-4f7c-9017-50693b2f9c1d
let
	bf = Tablet(; a=:A, b=:B, c=:C, d=:D, threading=BackToFront())
	rotate!(bf, Forward())
	@assert bf.this_shot_rotation == 1
	rotate!(bf, Backward())
	@assert bf.this_shot_rotation == 0
	
	fb = Tablet(; a=:A, b=:B, c=:C, d=:D, threading=FrontToBack())
	rotate!(fb, Forward())
	@assert fb.this_shot_rotation == -1
	rotate!(fb, Backward())
	@assert fb.this_shot_rotation == 0

	bf.stacking = FrontToTheLeft()
	rotate!(bf, Forward())
	@assert bf.this_shot_rotation == -1
	rotate!(bf, Backward())
	@assert bf.this_shot_rotation == 0
	
	fb.stacking = FrontToTheLeft()
	rotate!(fb, Forward())
	@assert fb.this_shot_rotation == 1
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

# ╔═╡ 9b217c54-ad77-4ce3-9715-cde19bed7bc4
"""
    threads0(::Tablet)
return the threads of the unrotated Tablet in the order
1. top corner cloest to cloth beam -- hole **A**,
2. top corner furthest from cloth beam -- hole **B**,
3. bottom corner further from cloth beam -- hole **C**,
4. bottom corner closest to cloth beam -- hole **D**.
"""
function threads0(t::Tablet)
	if isa(t.threading, BackToFront)
		[t.a, t.b, t.c, t.d]
	else
		[t.b, t.a, t.d, t.c]
	end
end

# ╔═╡ 10388ccf-6c52-4113-b34d-e5a54ebec2a7
"""
    threads(::Tablet)
Return the threads of the tablet as rotated, in the order
1. top corner cloest to cloth beam,
2. top corner furthest from cloth beam,
3. bottom corner further from cloth beam,
4. bottom corner closest to cloth beam.
"""
function threads(t::Tablet)
	ts = threads0(t)
	[ ts[1 + mod(i - t.accumulated_rotation, 4)] for i in 0:3 ] 
end

# ╔═╡ e275a226-c404-4e8b-a9de-2b126da4b452
let
	t = Tablet(; a=:A, b=:B, c=:C, d=:D)
	@assert threads(t) == [:A, :B, :C, :D]
	t.accumulated_rotation = 1
	@assert threads(t) == [:D, :A, :B, :C]
	html"threads() assertions passed."
end

# ╔═╡ 98151391-5799-4e96-b1c5-8098dd45b396
"""
   shed_edge(::Tablet)

Return the edge number of the edge of the tablet that is facing the shed.
"""
function shed_edge(t::Tablet)
	# Should we consider this_shot_rotation?
	# FIX THIS TO ACCOUNT FOR STACKING.
	r = mod(t.accumulated_rotation , 4)
	if r == 0 4
	elseif r == 1 3
	elseif r == 2 2
	else 1
	end
end

# ╔═╡ f7e02d45-6de4-408c-99a0-ecaa274c6f39
"""
    top_edge(::Tablet)

Return the number of the top edge of the tablet.
This edge number is eaqsier to see on the loop than the shed edge.
"""
function top_edge(t::Tablet)
	# t.stacking affects which edge faces the shed but not which is on top
	# since changing t.stacking can only be done by flipping the card on its
	# vertical axis.
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
	t.accumulated_rotation += t.this_shot_rotation
	thrds = threads(t)
	stitchslant = t.this_shot_rotation > 0 ? '/' : '\\'
	front, back, slant = if t.this_shot_rotation > 0
		thrds[1], thrds[3], stitchslant
	else
		thrds[2], thrds[4], stitchslant
	end
	t.this_shot_rotation = 0
	return front, back, slant
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

# ╔═╡ a68fe666-2be8-421e-9c1a-6eb4d4e56ef5
map(threads, stablets)

# ╔═╡ 3c43dd0f-d8d4-460b-a8da-64b3831f6873
map(threads, ztablets)

# ╔═╡ 7edb81bb-3909-4e57-9028-60508b560509
let
	tablet = Tablet(a=Gray(0.2), b=Gray(0.4), c=Gray(0.6), d=Gray(0.8))
	# We expect the colors to be D, A, B, C
	map(0:7) do rot
		tablet.accumulated_rotation = rot
		threads(tablet)[1]
	end
end

# ╔═╡ d0feb96c-1350-41f2-8a43-39ae74042c27
let
	tablet = Tablet(; a=Gray(0.2), b=Gray(0.4), c=Gray(0.6), d=Gray(0.8),
	                stacking=FrontToTheLeft())
	# We expect the colors to be D, A, B, C
	map(0:7) do rot
		tablet.accumulated_rotation = rot
		threads(tablet)[1]
	end
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
	# Gray .val
end

# ╔═╡ c4804cf2-85ba-4895-8404-47560df04e2f
function chart_tablet(tablet::Tablet)
	@assert tablet.accumulated_rotation == 0
	@assert tablet.this_shot_rotation == 0
	grid_style =
		"display: inline-grid; " *
		"grid-template-columns: 1; " *
		"grid-template-rows: 1fr 1fr 1fr 1fr 1fr; "
	result = m("div", style=grid_style,
		m("span", style="background: $(csscolor(tablet.a));"),
		m("span", style="background: $(csscolor(tablet.b));"),
		m("span", style="background: $(csscolor(tablet.c));"),
		m("span", style="background: $(csscolor(tablet.d));"),
		m("span", threading_char(tablet.threading)))
	result
end

# ╔═╡ fd40ecf7-83cb-43b5-b87c-8273f8fd32c4
string(chart_tablet(Tablet{Color}(;
	a=RGB(1, 0, 0),
	b=RGB(0, 1, 0),
	c=RGB(0, 0,1),
	d=RGB(0.5, 0.5, 0.5))))

# ╔═╡ 22c96c85-2344-46bc-a64c-460414575677
function chart_tablets(tablets::Vector{Tablet})

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

# ╔═╡ 716bb7f6-d341-4828-8e31-8b135f7c016a
function tablet_weave(tablets, rotation::RotationDirection, count::Int)
	tapestry_top = []
	tapestry_bottom = []
	rotations = []
	stitchlength, stitchwidth = 4, 3
	blank = Gray(0.25)
	for row in 1 : count
		push!(rotations,
			transpose(map(tablets) do t
				t.accumulated_rotation
			end)
		)
		# Form the new shed:
		map(tablets) do t
			rotate!(t, rotation)
		end
		# Throw the weft:
		weave = map(shot!, tablets)
		push!(tapestry_top,
			map(weave) do w
				top, bottom, slant = w
				color_stitch(stitch_image(stitchlength, stitchwidth, slant),
							 top, blank)
			end)
		push!(tapestry_bottom,
			map(weave) do w
				top, bottom, slant = w
				color_stitch(stitch_image(stitchlength, stitchwidth, slant),
							 bottom, blank)
			end)
	end
	return vcat(map(tapestry_top) do row
					hcat(row...)
				end),
		   vcat(map(tapestry_bottom) do row
		   			hcat(row...)
		   end),
		   rotations
end

# ╔═╡ 296a64b9-7f7b-4ae2-adad-640be4879e7f
tablet_weave(make_chevron_tablets(), Forward(), 16)

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

# ╔═╡ 93497aa8-ba19-45fe-a596-dd5ef194229f
tablet_weave(make_diamond_tablets(), Forward(), 16)

# ╔═╡ ee85e6c6-2ade-4178-8850-55e776916ac1
md"""
## How to Describe Tablet Motion During Weaving

After each throw, each tablet must be rotated **forward** or **backward** to make
a new shed.  In the simplest patterns, all tablets are rotated in the same
direction.  For our gray code pattern however, tablets move in different
directions for each shed.  How can we represent these rotations for ease of
execution by the weaver.

There is one set of tablet motions for each throw of the shuttle.  We should have
a row number.  The weaver muust keep track of which row they're working.

There is motion for each tablet.  The motion of a single tablet can be concisely
described by unicode arrows () or by the edge number of the tablet that is facing
the shed.  The latter is less error prone since an incorrect starting position
for a tablet will be detected.

The simplest representation is a `Vector` for for the whole pattern each throw.
Each element would be a `Vector` of digits rfom `1` to `4` indicating the edge
of the tablet that's at the back of the shed.
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

# ╔═╡ 11ac0388-eadf-48c7-8ec9-2c4ce0f5169f
let
	border_color =RGB(0.5, 0.5, 0.5)
	color1 = RGB(1, 0, 0)
	color2 = RGB(0, 1, 0)
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
	(2 * border1) + (2 * border2)
end

# ╔═╡ 6dc90672-f80e-4e2c-9689-7e777b03ff8d
"""
    tablets_for_image(image)
Return a `Vector` of the `Tablet`s that could be used to weave the image, which should
be a two dimensional array.  If the tablets can't be determined then an error is
thrown.
The shorter dimension of `image` will be the weft, the larger, the warp.
The caller might need to adjust the threading of the tablets afterwards.
"""
function tablets_for_image(image)
	@assert length(size(image)) == 2
	cardcount = minimum(size(image))
	throwcount = maximum(size(image))
	if size(image)[1] < size(image)[2]
		image = permutedims(image, [2, 1])
	end
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
tablets_for_image(GRAY_PATTERN)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
Hyperscript = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
OrderedCollections = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"

[compat]
Colors = "~0.12.8"
Hyperscript = "~0.0.4"
OrderedCollections = "~1.4.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "bd0d9bf754f39afa9d34f190995e15e4e3f01656"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

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

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"
"""

# ╔═╡ Cell order:
# ╟─89e97690-18a6-11ed-15e4-4bb0cd5b7c50
# ╠═9c0b434e-571c-4181-9350-848d50ba42e9
# ╟─590963b9-bd0f-4c32-a778-873d22ec9c0f
# ╠═a3b3c00d-425d-4437-b964-50946b7e75b3
# ╠═e147b976-9227-4d54-8b14-f05d8eb0d42e
# ╠═fcb7d96f-f2ce-44cb-ac86-3ef6a6195bf4
# ╠═b04d2b69-aa8a-4174-8ef8-3e6b797354e7
# ╠═c2b1f51e-77fb-4e23-94cc-699c124b81c3
# ╠═78e317ca-d347-45a9-9058-b2e7b187c843
# ╟─1cf1cf59-d324-447a-8a72-b393c96b549f
# ╟─68c32382-4511-4345-a523-d9854b91e754
# ╠═786f8502-a081-4baf-b82d-a936cdfaae5e
# ╠═6d65f0b3-7370-4a7d-82bc-607f8b0f8c8c
# ╠═b12c2fe2-a32e-4e6f-a7d7-cfc24e8cb00c
# ╠═0fea18b7-b40e-4ca5-95e5-744e619ea14a
# ╟─31bdd4ca-aa24-4600-9a72-36410636019b
# ╠═bf12e28b-6bd1-45e3-9cea-e81d412c0097
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
# ╟─b396b71e-8510-4f7c-9017-50693b2f9c1d
# ╟─ede7b3b1-5ec6-4abe-95c2-72b68552695a
# ╠═9b217c54-ad77-4ce3-9715-cde19bed7bc4
# ╟─10388ccf-6c52-4113-b34d-e5a54ebec2a7
# ╟─e275a226-c404-4e8b-a9de-2b126da4b452
# ╠═98151391-5799-4e96-b1c5-8098dd45b396
# ╠═f7e02d45-6de4-408c-99a0-ecaa274c6f39
# ╟─ea0b660e-9512-4ad1-b99a-e17753f47d74
# ╟─776e4a65-62f7-4201-b8e5-6d5326e653fa
# ╠═98bb29dc-55e7-4f42-8456-d72079801a3a
# ╠═a68fe666-2be8-421e-9c1a-6eb4d4e56ef5
# ╠═3c43dd0f-d8d4-460b-a8da-64b3831f6873
# ╠═7edb81bb-3909-4e57-9028-60508b560509
# ╠═d0feb96c-1350-41f2-8a43-39ae74042c27
# ╟─c6a06609-bf84-45cb-a837-68760b826cb3
# ╟─a24eae67-f116-4c75-8fda-b942dab326c7
# ╠═3c10060e-f2e1-4a05-8322-65009f5ef14e
# ╠═c4804cf2-85ba-4895-8404-47560df04e2f
# ╠═fd40ecf7-83cb-43b5-b87c-8273f8fd32c4
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
# ╠═716bb7f6-d341-4828-8e31-8b135f7c016a
# ╠═296a64b9-7f7b-4ae2-adad-640be4879e7f
# ╠═eef97e76-284b-456f-9ad8-9b86d87d6954
# ╠═93497aa8-ba19-45fe-a596-dd5ef194229f
# ╟─ee85e6c6-2ade-4178-8850-55e776916ac1
# ╟─910c1e57-f7f0-4cb9-aa6c-826ff71e7b3a
# ╠═11ac0388-eadf-48c7-8ec9-2c4ce0f5169f
# ╠═6dc90672-f80e-4e2c-9689-7e777b03ff8d
# ╠═4bd5b024-9be5-42f3-999b-6d9300003dd9
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
