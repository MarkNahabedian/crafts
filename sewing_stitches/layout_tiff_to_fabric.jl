# Arrange the TIFF files representing our stitch pages to fit a
# specified fabric width.

using Images
using Unitful
using Logging

function layout_tiff_images(famric_width)
    images = collect(values(TIFF_FILES))
    count = length(images)
    @assert allequal(image_Xresolution, images)
    @assert allequal(image_Yresolution, images)
    @assert allequal(image_width, images)
    @assert allequal(image_height, images)
    X_resolution = image_Xresolution(images[1])
    Y_resolution = image_Yresolution(images[1])
    tiff_width = image_width(images[1])
    tiff_height = image_height(images[1])
    across = floor(famric_width / tiff_width)
    # Assumes all images are the same size:
    rowcount = ceil(count / across)
    leftover_width = famric_width - across * tiff_width
    @info("Fabric grid layouut",
    count, X_resolution, Y_resolution,
    tiff_width, tiff_height,
    across, leftover_width, rowcount)
    # save("stitch_pages.tiff", p)
end


