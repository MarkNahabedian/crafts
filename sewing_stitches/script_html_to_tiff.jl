
include("stitches.jl")
include("generate_html.jl")

BROWSER = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

for stitch in values(SEWING_STITCHES)
    htmlfile = joinpath(@__DIR__, html_file_name(stitch))
    base, _ = splitext(htmlfile)    
    pdffile = base * ".pdf"
    tiffile = base * ".tiff"
    # /Google Chrome.app/Contents/MacOS/Google Chrome' --headless --disable-gpu --print-to-pdf="temp.pdf" FOLE.html
    run(Cmd([BROWSER, "--headless", "--disable-gpu",
             "--print-to-pdf=$pdffile", htmlfile]);
        wait=true)
    #=
    # This command doesn't give the right sisez because sips is too smartass:
    run(Cmd(["sips", "-s", "format", "tiff",
             "-r", "200",
             "--resampleHeightWidth", "2000", "1600",
             # "--setProperty",  "dpiWidth", "200",
             # "--setProperty",  "dpiHeight", "200",
             pdffile, "--out", tiffile]);
    wait=true)
    =#
    run(Cmd([ "pdftoppm", "-tiff",
              "-r", "200",
              "-f", "1", "-l", "1",
              "-singlefile",
              pdffile, base
              ]),
        wait=true)
    println("Wrote $base.tif")
end

