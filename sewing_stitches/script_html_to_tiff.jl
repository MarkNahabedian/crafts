
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
    # sips -s format tiff "temp.pdf" --out "${file%.html}.tiff"
    run(Cmd(["sips", "-s", "format", "tiff", pdffile, "--out", tiffile]);
        wait=true)
    println("Wrote $tiffile")
end

