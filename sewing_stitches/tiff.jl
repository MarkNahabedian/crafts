using Unitful
using TiffImages

function image_size_units(img::TiffImages.AbstractTIFF)
    u = ifds(img)[TiffImages.RESOLUTIONUNIT].data
    if u == 2
        u"inch"
    elseif u == 3
        u"cm"
    else
        error("Unknown RESOLUTIONUNIT tag value: $u")
    end
end

function image_width(img::TiffImages.AbstractTIFF)
    imagewidth = convert(Rational{Int}, ifds(img)[TiffImages.IMAGEWIDTH].data)
    xresolution = convert(Rational{Int}, ifds(img)[TiffImages.XRESOLUTION].data)
    return image_size_units(img) * imagewidth / xresolution
end

function image_height(img::TiffImages.AbstractTIFF)
    imagelength = convert(Rational{Int}, ifds(img)[TiffImages.IMAGELENGTH].data)
    yresolution = convert(Rational{Int}, ifds(img)[TiffImages.YRESOLUTION].data)
    return image_size_units(img) * imagelength / yresolution
end


# See # https://www.loc.gov/preservation/digital/formats/content/tiff_tags.shtml
# for tag definitions.

INTERESTING_TIFF_TAGS = [
    TiffImages.IMAGEWIDTH,
    TiffImages.IMAGELENGTH,
    TiffImages.XRESOLUTION,
    TiffImages.YRESOLUTION,
    TiffImages.RESOLUTIONUNIT 
]

TAG_VALUE_DISPLAY_FUNCTIONS = Dict([
    TiffImages.XRESOLUTION => (x -> convert(Rational{Int}, x)),
    TiffImages.YRESOLUTION => (y -> convert(Rational{Int}, y)),
    TiffImages.RESOLUTIONUNIT => image_size_units
])

tag_value_display_function(tag) = get(TAG_VALUE_DISPLAY_FUNCTIONS, tag, identity)

#=

282 XResolution   The number of pixels per ResolutionUnit in the ImageWidth direction.
283 YResolution   The number of pixels per ResolutionUnit in the ImageLength direction.
296 ResolutionUnit   The unit of measurement for XResolution and YResolution.

Xresolution is a Rational; ImageWidth (Tag 256) is the numerator and
the length of the source (measured in the units specified in
ResolutionUnit (Tag 296)) is the denominator.

If Tag 296 = 1: No absolute unit of measurement. The ratio of
XResolution to YResolution only specifies the aspect ratio of the
pixels.

If Tag 296 = 2: The unit is Inches. The values in Tags 282 and 283 are
your exact Pixels Per Inch (PPI).

If Tag 296 = 3: The unit is Centimeters. The values in Tags 282 and
283 are Pixels Per Centimeter (PPCM).

According to the official TIFF specification, when these tags are
omitted, the default resolution value is 72 DPI (pixels per
inch). Additionally, the default Tag 296 (ResolutionUnit)
automatically reverts to 2 (Inches).

=#

function size_info(img::TiffImages.AbstractTIFF)
    println("\n$(image_width(img)) ", Char(0xD7), " $(image_height(img))")
    for tag in INTERESTING_TIFF_TAGS
        try
            println("#", Int(tag), "\t", tag, "\t",
                    tag_value_display_function(tag)(ifds(img)[tag].data))
        catch e
        end
    end
end


TIFF_FILES = Dict()

function load_tiff_files()
    for filename in readdir()
        if !endswith(filename, ".tif")
            continue
        end
        TIFF_FILES[filename] = TiffImages.load(filename)
    end
end


    
