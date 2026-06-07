using Unitful
include("includes.jl")

# HTML files:
format_all_stitch_pages()
html_to_tiff()

load_tiff_files()
layout_tiff_images(u"43inch")

