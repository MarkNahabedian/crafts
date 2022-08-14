### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# ╔═╡ 9c0b434e-571c-4181-9350-848d50ba42e9
begin
	using Base: kwdef
	using Colors
	using Markdown
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

# ╔═╡ c2b1f51e-77fb-4e23-94cc-699c124b81c3
map(hcat(gray_sequence...)) do bit
	COLORS[bit + 1]
end

# ╔═╡ fa0380d3-78b0-406c-8c38-182c22877591
md"""
## Tablets

Looking at the front of a "tablet" card, the holes are labeled
**A**, **B**, **C**, and **D** clockwise.

To simplify how to understand tablet weaving patterns, imagine
that size isn't an issue.  We can arrange the cards to be
co-planar and side by side across the width of the loom, with the
front of the card facing the weaver (and the cloth beam).

A warp thread runs from the warp beam through a hole in the card
from back to front and then from the front of the card to the
cloth beam.

If the card is rotated clockwise for the next shot, the thread
running through its top left hole (before rotation) will form a
diagonal stitch on top of the fabric.  That stitch will slant
from left to right going towards the cloth beam.  Simultaneously,
the thread in the bottom right hole forms a stitch across the
underside of the fabric from right to left.  The thread in the
top right hole passes through the fabric from front to back, and
the thread in the bottom left hole passes through the fabric from
back to front.

Unfortunately, we are encumbered by Euclidean, rather than
Topological space, so size does matter.  For this reason we must
rotate the cards on their vertical axes so that they stack
together from left to right.  If the card is turned such that its
right edge moves toward the warp beam then the card is said to be
**S** threaded.  if it is turned the other way -- left edge
towards the back -- it is saif to be **Z** threaded.  Another way
of visualizing it is that, looking down at a card from the top,
the thread moves in the same direction as the diagonal line in
the weaving pattern.

Note that during weaving, any card can be flipped on
its (current) vertical axis to change its threading from **S** to
**ZZ** of **Z** to **S**.
"""

# ╔═╡ 0fea18b7-b40e-4ca5-95e5-744e619ea14a
@kwdef mutable struct Tablet{T}
	id = nothing
	a::T
	b::T
	c::T
	d::T
	sz = :s
	accumulated_rotation::Int = 0
	this_shot_rotation::Int = 0
end

# ╔═╡ 86033a92-cd04-4c52-845d-89a8a473506c
abstract type RotationDirection end

# ╔═╡ 56453fbd-6f6a-4c11-b2ba-acae84b66f48
md"""
### Tablet Rotation

Prior to each new throw of the weft, the tablets are rotated to
open a new shed.  One can think of the cards as rotating
**clockwise** or **counterclockwise** if the cards are arranged
in our simplified "size doesn't matter" topological arrangement.

If the card's hole order was **A**, **B**, **C**, **D** before
rotating clockwise it becomes **D**, **A**, **B**, **C** after.

In practice (the stacked arrangement), a card will be rotated
**forward** or **backward**.  Forward rotation moves the top
corner of the card closest to the weaver away from the weaver
towards the warp beam.  Backward rotation moves the top corner
furthest from the weaver toards the weaver.

Whether **forward** rotation turns the card **clockwise** or
**counterclockwse** depends on how the card is threaded.

"""

# ╔═╡ bb8a5f20-62af-4f28-b0df-85af57beb8f3
begin
	struct Clockwise <: RotationDirection end
	struct CounterClockwise <: RotationDirection end
	struct Forward <: RotationDirection end
	struct Backward <: RotationDirection end
end

# ╔═╡ 50e521b5-c4f7-464d-b6dd-5c7f9d5b4bd0
"""
    rotate!(::Tablet, ::AbstractDirection)
Rotate the tablet by one position in the specified direction.
"""
function rotate! end

# ╔═╡ 9d85d3ef-847b-405c-817b-71097b56fee5
function rotate!(t::Tablet, ::Clockwise)
	new_rotation = t.this_shot_rotation + 1
	t.this_shot_rotation = new_rotation
	return t
end

# ╔═╡ 748199f2-e5d8-4272-9120-f8b50264b5d6
function rotate!(t::Tablet, ::CounterClockwise)
	new_rotation = t.this_shot_rotation - 1
	t.this_shot_rotation = new_rotation
	return t
end

# ╔═╡ 30c08bee-e3f9-4672-a4d6-29df3ba8a6e5
rotate!(t::Tablet, ::Forward) =
	rotate!(t,
		if t.sz == :s
			Clockwise()
		else
			CounterClockwise()
		end
	)

# ╔═╡ 6d796003-f336-44ed-8831-8ea2b56fe865
rotate!(t::Tablet, ::Backward) =
	rotate!(t,
		if t.sz == :z
			CounterClockwise()
		else
			Clockwise()
		end
	)

# ╔═╡ 9b217c54-ad77-4ce3-9715-cde19bed7bc4
"""
    threads0(::Tablet)
return the threads of the unrotated Tablet in order.
"""
threads0(t::Tablet) = [t.a, t.b, t.c, t.d]

# ╔═╡ 10388ccf-6c52-4113-b34d-e5a54ebec2a7
"""
    threads(::Tablet)
Return the threads of the tablet as rotated.
"""
function threads(t::Tablet)
	ts = threads0(t)
	[ ts[1 + mod(i - t.accumulated_rotation, 4)] for i in 0:3 ] 
end

# ╔═╡ ea0b660e-9512-4ad1-b99a-e17753f47d74
"""
    shot!(::Tablet)
Applies the current rotation to the tablet and returns the colors of the warp threads passing over the top and bottom of the fabric, and the crossing direction (as a forward or backslash character) when looking at that face of the fabric.
"""
function shot!(t::Tablet)
	@assert(abs(t.this_shot_rotation) == 1,
		"in shot!, this_shot_rotation = $(t.this_shot_rotation)")
	t.accumulated_rotation += t.this_shot_rotation
	thrds = threads(t)
	front, back, slant = if t.this_shot_rotation > 0
		thrds[1], thrds[3], '/'
	else
		thrds[2], thrds[4], '\\'
	end
	t.this_shot_rotation = 0
	return front, back, slant
end

# ╔═╡ 776e4a65-62f7-4201-b8e5-6d5326e653fa
md"""
For a given `Tablet`, if `a` and `b` are one color and `c` and `d` are another, then we can rotate the tablet in one direction to change colors and the other to keep the color the same.  We can't control the slant of the stitch though.
"""

# ╔═╡ 98bb29dc-55e7-4f42-8456-d72079801a3a
tablets = [Tablet(; id = i, a=COLORS[3], b=COLORS[3], c=COLORS[2], d=COLORS[2],
	accumulated_rotation = i - 1)
	for i in 1:8
]

# ╔═╡ 8b7572b3-203c-4063-8787-c8a4a23f2a61
md"""

"""

# ╔═╡ 3c43dd0f-d8d4-460b-a8da-64b3831f6873
map(threads, tablets)

# ╔═╡ 418c2904-d16a-4c2d-a02f-c069918dca4c
md"""
## Stitches

How do we render stitches so we can see how our pattern might come out.
"""

# ╔═╡ abacffda-7c76-46cc-8e3c-e305a81b5702
"""
	stitch_image(length, width, direction)
Make a lengthh by width Bool array that will bve used to draw a stitch after
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
		# Note that the Y axis is flipped.
		direction == '/' ? -1 : 1)

# ╔═╡ 4ace6327-de0b-43fa-9b42-33661152de49
[ stitch_image(8, 4, 1), stitch_image(8, 4, -1) ]

# ╔═╡ 326c169a-2386-4e5d-97eb-3f6b6f691b9f
"""
    color_stitch(stitch_image, foreground::Color, background::Color)
Return a `Matrix` of `Color` with the same dimensions as stitch_image (which should have been constructed by `stitch_image`).
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
["Simple Diamonds.. err Chevrons"](https://www.pinterest.com/pin/363525001170926977/) and will try to implement/replicate it here.

"""

# ╔═╡ c3d99a5c-9c4c-4aff-b932-2dcc45a392ce
function make_chevron_tablets()
	foreground = RGB(map(x -> x/255, Colors.color_names["yellow3"])...)
	border = Gray(1)
	background = Gray(0)
	id = 0
	function tab(a, b, c, d, sz)
		id += 1
		Tablet{Color}(id, a, b, c, d, sz, 0, 0)
	end
	[
		# Border:
		tab(background, background, background, background, :z),
		tab(border, border, border, border, :z),
		tab(background, background, background, background, :s),
		# Pattern:
		tab(background, background, background, foreground, :s),
		tab(background, background, foreground, background, :s),
		tab(background, foreground, background, background, :s),
		tab(foreground, background, background, background, :s),
		tab(foreground, background, background, background, :z),
		tab(background, foreground, background, background, :z),
		tab(background, background, foreground, background, :z),
		tab(background, background, background, foreground, :z),
		# Border:
		tab(background, background, background, background, :z),
		tab(border, border, border, border, :s),
		tab(background, background, background, background, :s)
	]
end

# ╔═╡ 716bb7f6-d341-4828-8e31-8b135f7c016a
let
	# Try continuous forward rotation
	chevron_tablets = make_chevron_tablets()
	tapestry = []
	rotations = []
	for row in 1:16
		push!(rotations,
			transpose(map(chevron_tablets) do t
				t.accumulated_rotation
			end)
		)
		# Form the new shed:
		map(chevron_tablets) do t
			rotate!(t, Forward())
		end
		# Throw the weft:
		push!(tapestry,
			map(chevron_tablets) do t
				top, bottom, angle = shot!(t)
				color_stitch(stitch_image(4, 3, angle),
					top, Gray(0.25))
					end)
	end
	vcat(map(tapestry) do row
			hcat(row...)
	end...) # , rotations
end

# ╔═╡ 910c1e57-f7f0-4cb9-aa6c-826ff71e7b3a
md"""
## Generating a Pattern

We have an array of the "image" we want to weave.  How do we translate that into a set of tablets and their motions?

How do we execute that "plan" to produce a stitch image to see how the pattern turned out.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"

[compat]
Colors = "~0.12.8"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

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

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
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
# ╟─fa0380d3-78b0-406c-8c38-182c22877591
# ╠═0fea18b7-b40e-4ca5-95e5-744e619ea14a
# ╠═86033a92-cd04-4c52-845d-89a8a473506c
# ╟─56453fbd-6f6a-4c11-b2ba-acae84b66f48
# ╠═bb8a5f20-62af-4f28-b0df-85af57beb8f3
# ╟─50e521b5-c4f7-464d-b6dd-5c7f9d5b4bd0
# ╟─9d85d3ef-847b-405c-817b-71097b56fee5
# ╟─748199f2-e5d8-4272-9120-f8b50264b5d6
# ╟─30c08bee-e3f9-4672-a4d6-29df3ba8a6e5
# ╟─6d796003-f336-44ed-8831-8ea2b56fe865
# ╟─9b217c54-ad77-4ce3-9715-cde19bed7bc4
# ╟─10388ccf-6c52-4113-b34d-e5a54ebec2a7
# ╟─ea0b660e-9512-4ad1-b99a-e17753f47d74
# ╟─776e4a65-62f7-4201-b8e5-6d5326e653fa
# ╠═98bb29dc-55e7-4f42-8456-d72079801a3a
# ╠═8b7572b3-203c-4063-8787-c8a4a23f2a61
# ╠═3c43dd0f-d8d4-460b-a8da-64b3831f6873
# ╟─418c2904-d16a-4c2d-a02f-c069918dca4c
# ╠═abacffda-7c76-46cc-8e3c-e305a81b5702
# ╠═ca9cae4a-f74b-46e7-9a24-fc8df3958a0f
# ╠═4ace6327-de0b-43fa-9b42-33661152de49
# ╟─326c169a-2386-4e5d-97eb-3f6b6f691b9f
# ╠═4853d329-c7e4-4a98-b057-4192513b0220
# ╟─8aa9c975-ff50-4db0-9939-7fee0cada96a
# ╠═c3d99a5c-9c4c-4aff-b932-2dcc45a392ce
# ╠═716bb7f6-d341-4828-8e31-8b135f7c016a
# ╟─910c1e57-f7f0-4cb9-aa6c-826ff71e7b3a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
