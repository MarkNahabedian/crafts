# Procedure for Making Stitches Artwork for Cricut


## Generate the HTML files

```
julia

include("stitches.jl")

format_all_stitch_pages()

exit()
```


## Convert Each HTML File to PDF in Firefox

Do this for each stitch file:

Open a page in Firefox.
Print...
Save to PDF
Pages: current
under More Settings choose
Scale 100; margins none
and turn off "Print headers and footers" and "print backgrounds".
SDave
Remove ".html" from file name in dialog.
Save.

Note: Firefox saves the files in `~/Documents`.


## Convert Each PDF File to SVG in Inkscape

Open the resulting PDF file in Inkscape:

### New Document

File > New From Template, custom, Cricut 72dpi
File > Import...
Clip to: Media Box
Fonts: draw all text
Turn off Embed Images and Import Pages.
Ok.

### Verify document properties:

File > Document Properties...
Make sure `Custom` is selected.
Select inches for both units.
Width: 8
Height: 10
Viewbox: 0 0 576 720
Turn all checkboxes off.    ????

### Convert to single stroke fonts:

menu bar > Extensions > Text > Hershey Text
Font face: Hershey Sans 1 stroke.
Don't select "preserve original text".
Apply.
Close the Hershey dialog.

### Save SVG file:

Menu bar > File > Save as:

Select "Plain SVG" file format
Fixup the file name.
Save.

Note: The file is saved to `~/Documents`.


## Cleanup SVG


## Open in Cricut Design Space

Skip new product setup.

File > New Canvas
Blank Canvas
Upload (from near bottom of left edge toolbar)
Upload image
browse to select file
