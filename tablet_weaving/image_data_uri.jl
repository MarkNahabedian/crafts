# Construct a "data:" URI for an image.

using Base64
using FileIO

IMG_DATA_PREFIX = "data:image/png;base64,"

function image_data_uri(image)
    io = IOBuffer()
    save(Stream(format"PNG", io), image)
    IMG_DATA_PREFIX * base64encode(take!(io))
end

