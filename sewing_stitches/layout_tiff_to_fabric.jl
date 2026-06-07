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
    fabric_width_pixels = famric_width * X_resolution
    surplus_width = fabric_width_pixels - across * tiff_width * X_resolution
    # Assumes all images are the same size:
    rowcount = ceil(count / across)
    leftover_width = famric_width - across * tiff_width
    padding_width_pixels = convert(Int, surplus_width / (across + 1))
    padding_height_pixels = convert(Int, tiff_height * Y_resolution)
    @info("Fabric grid layouut",
          count, X_resolution, Y_resolution,
          tiff_width, tiff_height,
          across, leftover_width, surplus_width,
          padding_width_pixels, padding_height_pixels,
          rowcount)
    # Tile the images: Do we need to replace the white pixels with
    # transparent ones?  Where did the white pixels come from anyway?
    background_color = RGB{N0f8}(1.0, 1.0, 1.0)
    horizontal_padding_array = fill(background_color,
                                    padding_height_pixels,
                                    padding_width_pixels)
    image_row_vector = [horizontal_padding_array]
    for image in images
        push!(image_row_vector, image)
        push!(image_row_vector, horizontal_padding_array)
    end
    save("stitch_pages.tiff",
         hcat(image_row_vector...))
end

