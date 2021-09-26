NB. TODO: figure out how to load this file while developing
NB. *and* not hard-code my local path. (maybe just put my working
NB. copy of the git repo under addons?)
load 'd:/ver/gridpad/gridpad.ijs'
coinsert 'gridpad'

gpw_close^:(wdisparent'gpw')''
gpw_init ''
1920 1080 gpw''

img =: (pal {~ ])^:(>:0:)"0 parse_table (0 : 0)
11 10 13 13 13 13 13 11 11 11 11 13 _1 _1 _1 _1
11 11 10 10 10 11 11 11 11 13 13 13 13 _1 _1 _1
13 11 11 10 11 11 13 13 13 13 13 13 13 _1 _1 _1
13 11 10 11 11 10 10 10 13 13 13 13 13 13 13 _1
13 10 10 11 10 10 13 10 10 10 13 13 13 13 13 13
10 10 11 11 11 11 10 10 13 10 13 13 13 13 13 13
11 11 11 11  5 11 11 10 13 13 13 13 13 13 13 13
11 14 11 11  6 14 11 11 10 14 14 14 14 14 14 14
11 14 11 11  6 14 14 11 11 14 14 14 14 14 14 14
15 15  5 11  6 15 15 14 11 14 14 14 14 14 14 14
 7  7  6  5  6  7  7 15 15 15 15 15 15 14 14 14
 8  8  6  6  6  8  8  7  7  7  7  7  7 15 15 15
 8  8  6  6  6  8  8  8  8  8  8  8  8  7  7  7
 8  8  8  6  6  8  8  8  8  8  8  8  8  8  8  8
 8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8
 8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8
)


NB. helper to generate the image as table of
NB. indices. this only works if every color
NB. in the image is also in the palette.
imgtxt =: {{ {{pal i. 256 #. 256 256 256 #:y}}^:(-.@-:_1:)"0 img }}
