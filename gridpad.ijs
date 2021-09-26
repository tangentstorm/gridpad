NB. gridpad: a simple sprite editor
NB.
NB. Copyright (c)2019 Michal J Wallace
NB. Free for use under the MIT License.
NB.
NB. See the video where this was made here:
NB. https://youtu.be/CzK2SazvCxM
cocurrent'gridpad'

require 'viewmat png'
coinsert 'jviewmat jgl2'

NB. -- config -----------------------------------------------
NB. override these in your own locale.

NB. startup options: override these before calling gpw_init
gpo_title =: 'gridpad'
gpo_window =: 'nosize'
gpo_init_xy =: 10 500
gpo_timer =: 100
gpo_palv_wh =: 25 400
gpo_imgv_wh =: 480 480
gpo_bg =: _1                        NB. new image background color
gpo_statusbar =: 1                  NB. show status bar?
gpo_showgrid =: 1                   NB. show the grid by default? (can toggle at runtime)
gpo_gridrgb =: 255 255 255          NB. grid color
gpo_colorpick =: 1                  NB. allow color picker
gpo_viewmat =: 'rgb'                NB. viewmat options (x arg to vmcc)
gpo_menu =: noun define
  menupop "&File";
    menu new  "&New"  "Ctrl+N";
    menu open "&Open" "Ctrl+O";
    menu save "&Save" "Ctrl+S";
  menupopz;
  menupop "&View";
    menu grid "Toggle &Grid" "Ctrl+G";
  menupopz;
)

NB. -- palettes ---------------------------------------------
NB. shamelessly stolen from https://github.com/JohnEarnest/ok/tree/gh-pages/ike

parse_table =: {{ 0 ". > LF cut y -. CR }}

NB. default palette (16-color vga text-mode palette)
pal_vga =: ,parse_table 0 : 0
16b000000 16baa0000 16b00aa00 16baa5500 16b0000aa 16baa00aa 16b00aaaa 16baaaaaa
16b555555 16bff5555 16b55ff55 16bffff55 16b5555ff 16bff55ff 16b55ffff 16bffffff
)

NB. http://pixeljoint.com/forum/forum_posts.asp?TID=12795
pal_dawnbringer =: ,parse_table 0 : 0
16b140c1c 16b442434 16b30346d 16b4e4a4e 16b854c30 16b346524 16bd04648 16b757161
16b597dce 16bd27d2c 16b8595a1 16b6daa2c 16bd2aa99 16b6dc2ca 16bdad45e 16bdeeed6
)

NB. http://androidarts.com/palette/16pal.htm
pal_arne =: ,parse_table 0 : 0
16b000000 16b9d9d9d 16bffffff 16bbe2633 16be06f8b 16b493c2b 16ba46422 16beb8931
16bf7e26b 16b2f484e 16b44891a 16ba3ce27 16b1b2632 16b005784 16b31a2f2 16bb2dcef
)


NB. https://ethanschoonover.com/solarized/
pal_solarized =: ,parse_table 0 : 0
16b002b36 16b073642 16b586e75 16b657b83 16b839496 16b93a1a1 16beee8d5 16bfdf6e3
16bb58900 16bcb4b16 16bdc322f 16bd33682 16b6c71c4 16b268bd2 16b2aa198 16b859900
)

pal_windows =: ,parse_table 0 : 0
16bffffff 16bc0c0c0 16b808080 16b000000 16bff0000 16b00ff00 16bffff00 16b0000ff
16bff00ff 16b00ffff 16b800000 16b008000 16b808000 16b000080 16b800080 16b008080
)

NB. https://www.lexaloffle.com/pico-8.php
pal_pico =: ,parse_table 0 : 0
16b000000 16b1d2b53 16b7e2553 16b008751 16bab5236 16b5f574f 16bc2c3c7 16bfff1e8
16bff004d 16bffa300 16bffec27 16b00e436 16b29adff 16b83769c 16bff77ab 16bffccaa
)

pal_lcd =: ,parse_table 0 : 0
16b0f380f 16b306230 16b8bac0f 16b9bbc0f
)

pal_cga =: ,parse_table 0 : 0
16b000000 16bffffff 16b00ffff 16bff00ff
)

pal_hot =: ,parse_table 0 : 0
16b000000 16bffffff 16bff0000 16bffff00
)

pal_names =: cut'cga hot lcd vga windows dawnbringer arne pico solarized'


NB. -- initialization ---------------------------------------

NB. default image.
img =: 32 32 $ 0

pal =: pal_arne

pen =: <: # pal  NB. start with last color (white)

gpw_init =: verb define
  NB. TODO: take above configuration arguments as params
  wd'pc gpw closebutton ',gpo_window   NB. create window 'gpw'
  wd'pn *',gpo_title                   NB. add title
  gpw_init_controls''
  if. gpo_statusbar do.
    wd' cc sb statusbar'                   NB.   optional status bar
    wd' set sb addlabel text'              NB.   ... with status text
  end.
  wd 'ptimer ',":gpo_timer
  wd gpo_menu
  wd 'pshow'
  wd 'pmove ',":gpo_init_xy,0 0
  NB. store hwnd in the calling locale. This is so we can call psel later.
  NB. it's one of the few things in wd that doesn't cope with locales.
  gpw_hwnd =: wd 'qhwndp'
  render''                                 NB. force initial render in case timer is 0
)


gpw_init_controls =: verb define
  wd'bin v'                                NB. vertical bin
  wd' bin h'                               NB.   horizontal bin
  wd'  cc palv isigraph'                   NB.     isigraph for palette
  wd'     setwh palv ',":gpo_palv_wh
  wd'     set palv sizepolicy fixed fixed' NB.     keep palette from resizing
  wd'  cc imgv isidraw'                    NB.     square isidraw canvas
  wd'     setwh imgv ',":gpo_imgv_wh
  wd' bin z'                               NB.   /bin
)

gpw_close =: verb define                  NB. when 'gpw' close button clicked
  wd'ptimer 0; pclose'
)

vmcc =: verb define                       NB. invoke viewmat in a child control
  gpo_viewmat vmcc y
:
  'im cc' =. y
  wd 'psel ',":gpw_hwnd
  x vmcc_jviewmat_ (to_rgb im);cc         NB. blit the pixel data
  glpaint glsel cc                        NB. pick child control name and repaint
)

to_rgb =: ]                               NB. map img to rgb
to_argb =: (255*2^24) + to_rgb            NB. and to argb for saving png files
to_pal =: ]                               NB. hook for mapping rgb to indexed palette

NB. -- general routines -------------------------------------

update =: ]

TRANSPARENT =: _1

subdivide =: 2&([ #"0 1 #"0 2)

draw_transparency =: verb define
  transparent =. 2 2 $ TRANSPARENT
  checkerboard =. 016b333333 *1+ *3|i. 2 2
  NB. cut and then re-assemble image y
  t =. (2 2,:2 2) <@(checkerboard"_^:(transparent-:]));.3 y
  |:,./><@;"1 t
)

NB. gpw_render is here so you can call it without having to fiddle with locales.
render =: gpw_render0 =: verb define
  im =. draw_transparency subdivide img
  vmcc im;'imgv'
  if. gpo_showgrid do.
    'vw vh' =. glqwh glsel'imgv' [ 'ih iw' =. $ img
    glpen glrgb gpo_gridrgb
    gllines <. 0.5+ (0, ], vw, ])"0 (vh%ih) * i.ih
    gllines <. 0.5+ (], 0, vh,~])"0 (vw%iw) * i.iw
  end.
)


whichbox =: verb define              NB. which cell is the mouse over?
  |. <. y %~ 2 {. ".sysdata          NB. (only works inside mouse events)
)

mbl =: {{ 4 { 0".sysdata }}          NB. left mouse button
mbr =: {{ 8 { 0".sysdata }}          NB. right mouse button (may need to be 5 for 2 button mouse?)
                                     NB. https://code.jsoftware.com/wiki/User:Raul_Miller/J_Event_Handlers

inbounds =: dyad define
  *./ (x >: 0) *. x < y
)

pen_color =: verb define
  NB. this is so you can apply custom mappings between the
  NB. representation in the palette view and the underlying
  NB. data in the image. By default, we eithenr extract from
  NB. the palette using an index, or allow _1 to pass through
  NB. for transparent background.
  if. pen > 0 do. pen { pal else. pen end.
)

img_draw =: verb define
  NB. y is the (y,x) coordinates of the pixel to draw
  img img_draw y
:
  NB. dyadic form uses img as a temp if there are multiple canvases (e.g., sandcalc)
  if. y inbounds $x do.
    render img =: (pen_color'') (< y) } x
  end.
  img
)

gpw =: verb define
  NB. set img to y and bring gpw window to front.
  NB. optional x argument is window position
  '' gpw y
:
  if. y -.@-: '' do. render img =: y end.
  wd'psel ',":gpw_hwnd
  if. x -.@-: '' do. wd'pmove ',(":x),' 0 0' end.
  wd'ptop'
)

NB. -- parent event handler ---------------------------------

gpw_timer =: verb define
  NB. this is called on every tick while the wd ptimer is set
  render update y
)

NB. custom wdhandler.
NB. this is identical to the builtin, but sends errors to smoutput instead of wdinfo
NB. I did this because the built-in one has a nasty habit of generating infinite error loops.
NB. see dec 2019 thread on the j programming list
wdhandler =: 3 : 0
  wdq=: wd 'q'
  wd_val=. {:"1 wdq
  ({."1 wdq)=: wd_val
  if. 3=4!:0<'wdhandler_debug' do.
    try. wdhandler_debug'' catch. end.
  end.
  wd_ndx=. 1 i.~ 3 = 4!:0 [ 3 {. wd_val
  if. 3 > wd_ndx do.
    wd_fn=. > wd_ndx { wd_val
    if. 13!:17'' do.
      wd_fn~''
    else.
      try. wd_fn~''
      catch.
        wd_err=. 13!:12''
        if. 0=4!:0 <'ERM_j_' do.
          wd_erm=. ERM_j_
          ERM_j_=: ''
          if. wd_erm -: wd_err do. i.0 0 return. end.
        end.
        wd_err=. LF,,LF,.(}.^:('|'e.~{.));._2 ,&LF^:(LF~:{:) wd_err
        smoutput 'wdhandler';'error in: ',wd_fn,wd_err
      end.
    end.
  end.
  i.0 0
)

NB. -- shared event handlers --------------------------------

NB. keyboard events are widget-specific, but we want same for img/pal
gpw_imgv_char =: gpw_palv_char =: verb define
  gpw_char''  NB. this is so we can override in one place in the locale
)

gpw_char =: verb define
  NB. TODO: keyboard handler.
  return.
)

NB. mouse wheel on either control rotates through palette
gpw_imgv_mwheel =: gpw_palv_mwheel =: verb define
  pen =: (#pal)|pen-*{:".sysdata NB. sign of last item is wheel dir
  glpaint glsel'palv'
)


NB. -- image view -------------------------------------------

gpw_imgv_mblup =: verb define
  NB. left click to draw on the image
  img_draw whichbox imgv_cellsize''
)

gpw_imgv_mmove =: verb define
  if. gpo_statusbar do. wd 'set sb setlabel text *', sysdata[ ": whichbox imgv_cellsize'' end.
  if. mbl'' do. gpw_imgv_mblup'' end.
  if. mbr'' do. gpw_imgv_mbrup'' end.
)

imgv_cellsize =: verb define
  (glqwh glsel'imgv') % |.$ img
)

gpw_imgv_mbrup =: verb define
  tmp =. pen
  pen =: _1
  gpw_imgv_mblup''
  pen =. tmp
)

gpw_imgv_mbmup =: verb define
  NB. middle click to extract a color from image
  yx =. whichbox imgv_cellsize''
  c =. (<yx) { img
  if. c e. pal do. pen =: pal i. c else.
    smoutput 'color #',(hfd c),' is not in the palette.'
  end.
  glpaint glsel'palv'
)


NB. -- palette view -----------------------------------------

palv_cellsize =: verb define
  (glqwh glsel 'palv') % 1,#pal
)

gpw_palv_mblup =: verb define
  NB. left click palette to set pen color
  glpaint glsel 'palv' [ pen =: {. whichbox palv_cellsize''
)

gpw_palv_paint =: gpw_palv_paint0 =: verb define
  vmcc (,.pal);'palv'          NB. ,. makes pal a 2d array
  NB. draw a box around the current pen color:
  glbrush glrgba 0 0 0 0  [ h =. {: cellsize =. palv_cellsize''
  glrect 3, (3+pen*h), _5 _5 + cellsize [ glpen 5 [ glrgb 0 0 0
  glrect 3, (3+pen*h), _5 _5 + cellsize [ glpen 1 [ glrgb 3 $ 255

  NB. black box around everything:
  glrect 0 0, (glqwh 'pal') [ glpen 1 [ glrgb 0 0 0
)

gpw_palv_mbrup =: verb define
  if. gpo_colorpick do.
    pen =: {. whichbox {: palv_cellsize''   NB. same as mblup: set pen
    rgb =: ": 256 256 256 #: pen { pal      NB. get 'r g b' string for old color
    if. #rgb =. wd'mb color ',rgb do.       NB. show system color picker
      c =. 256 #. ".rgb                     NB. turn new string into new color
      pal =: c pen } pal                    NB. update the palette...
    end.
    glpaint glsel'palv'                     NB. ... and redraw it.
  end.
)


NB. -- menu handlers ----------------------------------------

gpw_new_button =: verb define
  render img =: ($img) $ gpo_bg
)

gpw_dir =: verb define
 if. noun = nc<'gpw_path' do. 0 pick fpathname gpw_path
 else. jpath'~User' end.
)

gpw_open_button =: verb define
  path =. wd 'mb open1 "Load a png file" "',(gpw_dir''),'" "PNG (*.png)"'
  if. #path do. render img =: (to_pal) readpng path end.
)

gpw_save_button =: verb define
  path =. wd 'mb save "Save image" "',(gpw_dir''),'" "PNG (*.png)"'
  if. #path do. (to_argb img) writepng gpw_path =: path end.
)

gpw_grid_button =: verb define
  render gpo_showgrid =: -. gpo_showgrid
)
