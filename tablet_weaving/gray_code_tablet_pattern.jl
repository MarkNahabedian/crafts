### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# ╔═╡ 9c0b434e-571c-4181-9350-848d50ba42e9
begin
	using Base: @kwdef
	using Colors
end

# ╔═╡ 89e97690-18a6-11ed-15e4-4bb0cd5b7c50
md"""
# Gray Code Tablet Weaving Pattern
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

# ╔═╡ 0fea18b7-b40e-4ca5-95e5-744e619ea14a
@kwdef mutable struct Tablet{T}
	id = nothing
	a::T
	b::T
	c::T
	d::T
	sz = :s
	accumulated_rotation::Int = 0
	this_shot_rotation = 0
end

# ╔═╡ 86033a92-cd04-4c52-845d-89a8a473506c
abstract type RotationDirection end

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
Rotatethe tablet by one position in the specified direction.
"""
function rotate! end

# ╔═╡ 9d85d3ef-847b-405c-817b-71097b56fee5
function rotate!(t::Tablet, ::Clockwise)
	new_rotation = t.this_shot_rotation + 1
	@assert abs(t.this_shot_rotation) <= 1
	t.this_shot_rotation = new_rotation
	return t
end

# ╔═╡ 748199f2-e5d8-4272-9120-f8b50264b5d6
function rotate!(t::Tablet, ::CounterClockwise)
	new_rotation = t.this_shot_rotation - 1
	@assert abs(t.this_shot_rotation) <= 1
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
			Clockwise()
		else
			CounterClockwise()
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
Return the threads of the tabloet as rotated
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
	@assert abs(t.this_shot_rotation) == 1
	t.accumulated_rotation += t.this_shot_rotation
	threads = threads(t)
	front, back, slant = if t.this_shot_rotation > 0
		threads[1], threads[3], '/'
	else
		threads[2], threads[4], '\\'
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

# ╔═╡ 3c43dd0f-d8d4-460b-a8da-64b3831f6873
map(threads, tablets)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"

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
# ╠═a3b3c00d-425d-4437-b964-50946b7e75b3
# ╠═e147b976-9227-4d54-8b14-f05d8eb0d42e
# ╠═fcb7d96f-f2ce-44cb-ac86-3ef6a6195bf4
# ╠═b04d2b69-aa8a-4174-8ef8-3e6b797354e7
# ╠═c2b1f51e-77fb-4e23-94cc-699c124b81c3
# ╠═0fea18b7-b40e-4ca5-95e5-744e619ea14a
# ╠═86033a92-cd04-4c52-845d-89a8a473506c
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
# ╠═3c43dd0f-d8d4-460b-a8da-64b3831f6873
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
