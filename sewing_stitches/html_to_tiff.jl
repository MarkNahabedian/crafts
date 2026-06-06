
# include("includes.jl")

pdf_file_name(stitch::SewingStitch) =
    base_file_name(stitch) * ".pdf"


BROWSER = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

function html_to_tiff()
    for stitch in values(SEWING_STITCHES)
        htmlfile = joinpath(@__DIR__, html_file_name(stitch))
        pdffile = joinpath(@__DIR__, pdf_file_name(stitch))
        tiffile = joinpath(@__DIR__, tiff_file_name(stitch))
        basefile = joinpath(@__DIR__, base_file_name(stitch))
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
                  pdffile, basefile
                  ]),
            wait=true)
        println("Wrote $basefile.tif")
    end
end


