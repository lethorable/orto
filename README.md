# orto
Small hack that makes ortho photos. 

### WARNING

###If you are starting from scratch to make orho photos you might be better off using a maintained project, for instance GRASS GIS or orfeo. This project is dormant, uses its own nomenclature, notation, only partly uses accepted standards, formats etc. Though this stuff works and I am happy to answer questions, NOW might be a good time to click on to the next new thing... Go on. I'm waiting... *

Oh well. You stayed. At your own peril. Here goes...

Orto is a small executable which can be used to calculate an ortho photo from... 

- uncompressed tiff files (8 or 16 bit per sample, 3 or 4 band, striped 
  or tiled)
- terrain models in various formats (triangles, ascii grids, esri asc)

It will create an output tiff image as

- 8 or 16 bits per sample (as defined by input)
- RGB, RGBi, CIR, NDVI

To run... 

- Edit demo.def to your liking
- Run with "orto.exe -def demo.def"
(can also be run entirely from command line)

To compile from source... 

- download and install Free Pascal (Lazarus)
- set up system path so fpc can be called
- compile with "fpc orto"

Refer to the demo.def file for an explanation of parameters.

It will work on *some* tiff formats. Mileage may vary. It has proven to 
be effective using gdal as a translator of the input imagery. For this 
a python script, shell script or bat file could do the trick of wrapping 
everytthing up in a workflow in one workflow. Also the elevation model 
needs to be translated into esri asc format. 

Good luck!


*Notes*

This software was spawned ca. 1998 as part of my thesis on automatic 
orientation of aerial images using ortho photos instead of ground 
control points - a discipline that modern GPS/IMU systems have rendered 
obsolete long ago. As part of the thesis it was necessary to transform 
a small ortho photo patch and correlate in an aerial image. This 
"engine" to generate ortho photos was soon after written and has proven 
to be stable and adequate for some professional and hobby projects along 
the years. I have had it in a dormant state for some years and felt it 
better to publish it so other people could benefit from it, contribute 
to it or embed elsewhere in whole or in parts. 

Along the years some of the original code has been used professionally 
(ca. 2004-2009) and had been changed to accommodate the needs of the 
company I worked for. This company went out of business years ago but to 
make absolutely sure to avoid any claims that could potentially arise I 
have done an effort to clean out this code and substitute it with new 
routines for the same purposes or revert to old code. This includes 
various vector file formats, in-house conversions, graphical user 
interface, error reporting, 12-bit image optimisations, parallel 
processing, batch tools etc. As a consequence of these roll back edits 
it is somewhat a bit of a patchwork at present - it is not as pretty as 
could be but it does a good job as it is now.

Everything is "as is" without warranty of any sort. Please refer to 
license.txt included in the package. If you use the software, I would 
love to hear about it (you don't have to, it is not a requirement. I am 
just curious) - drop me a line! :-)

Copenhagen, October 2013

Thorbjoern Nielsen 
t h o r b j o r n ( a t ) g m a i l ( d e c i m a i l ) c o m

Thanks to following persons: 

Andrew Flatman for testing, ideas and feedback

20190917: Ported to Github, readme amended


