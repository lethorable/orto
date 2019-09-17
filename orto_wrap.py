import os,sys
from argparse import ArgumentParser
import glob
from subprocess import call

path_to_orto='c://dev/orto/orto.exe'
temp_dir = 'c://temp'


#Example call:
# python orto_wrap.py -I test.tif -O otest.tif -DTM C:\data\dtm_grid_2007\dtm_2007.vrt -CON -0.15 -XDH 0 -YDH 0 -IL1 "0.014 0" -IL2 "0 -0.014" -IL3 "-10 10" -RES 0.1 -SZX 2000 -SZY 2000 -TLX AUTO -TLY AUTO -X_0 600000 -Y_0 6600000 -Z_0 500 -DRG DEG -OME 0 -PHI 0 -KAP 0  

progname=os.path.basename(__file__)
parser=ArgumentParser(description="Wrap for orto.exe - will translate DTM using osgeo4w",prog=progname)
parser.add_argument("-I",help="aerial image (tiff file)")
parser.add_argument("-O",help="output ortho image (tiff file)")
parser.add_argument("-DTM",help="GDAL readable terrain model")
parser.add_argument("-CON",help="Principal distance (camera constant) untis [m], must be negative (eg. -0.15012)")
parser.add_argument("-XDH",help="PPA (x' offset from PPS to PPA units [mm])")
parser.add_argument("-YDH",help="PPA (y' offset from PPS to PPA units [mm])")
parser.add_argument("-IL1",help="<D11 D12>")
parser.add_argument("-IL2",help="<D21 D22>")
parser.add_argument("-IL3",help="<dx' dy'>")
parser.add_argument("-RES",help="Resolution of output. Units [m] (ie. 0.1)")
parser.add_argument("-SZX",help="Size of output in x-direction. Units [cols]")
parser.add_argument("-SZY",help="Size of output in y-direction. Units [rows]")
parser.add_argument("-TLX",help="Top left x coordinate ie. 603630.30")
parser.add_argument("-TLY",help="Top left x coordinate ie. 6603630.30")
parser.add_argument("-X_0",help="Projection centre X")
parser.add_argument("-Y_0",help="Projection centre Y")
parser.add_argument("-Z_0",help="Projection centre Z")
parser.add_argument("-DRG",help="Units of rotation. Options are DEG RAD GRAD")
parser.add_argument("-OME",help="Omega")
parser.add_argument("-PHI",help="Phi")
parser.add_argument("-KAP",help="Kappa")

def usage():
	parser.print_help()
	
	
def main(args):
	pargs=parser.parse_args(args[1:])
	#call(path_to_orto)
	#print pargs.DTM
	
	tempnam = os.path.join(temp_dir,'tralala.asc')
	
	zc = 2* int(pargs.Z_0)
	xc=int(pargs.X_0)
	yc=int(pargs.Y_0)
	
	projwin = str(xc-zc)+' '+str(yc+zc)+ ' '+str(xc+zc)+' '+str(yc-zc)
	print projwin	

	
	gdalstr='gdal_translate -of AAIGrid '+pargs.DTM +' '+tempnam
	print gdalstr
	call('gdal_translate -of AAIGrid -projwin '+projwin+' '+pargs.DTM +' '+tempnam)
	
#	gdal_translate -of AAIGrid C:\data\dtm_grid_2007\dtm_2007.vrt c://temp\tralala.asc
	callstr = path_to_orto + \
	' -I '+pargs.I+\
	' -O '+pargs.O+\
	' -DTM '+tempnam+\
	' -CON '+pargs.CON+\
	' -XDH '+pargs.XDH+\
	' -YDH '+pargs.YDH+\
	' -IL1 '+pargs.IL1+\
	' -IL2 '+pargs.IL2+\
	' -IL3 '+pargs.IL3+\
	' -RES '+pargs.RES+\
	' -SZY '+pargs.SZY+\
	' -SZX '+pargs.SZX+\
	' -TLX '+pargs.TLX+\
	' -TLY '+pargs.TLY+\
	' -X_0 '+pargs.X_0+\
	' -Y_0 '+pargs.Y_0+\
	' -Z_0 '+pargs.Z_0+\
	' -DRG '+pargs.DRG+\
	' -OME '+pargs.OME+\
	' -PHI '+pargs.PHI+\
	' -KAP '+pargs.KAP
	call(callstr)
	os.remove(tempnam)
	
	
if __name__=="__main__":
	main(sys.argv)


