# mysticaltutor color scheme
declare-option -hidden str mt_black          'rgba:000000'
declare-option -hidden str mt_blue           'rgba:5C8EC7'
declare-option -hidden str mt_blue_bright    'rgba:A0B4CF'
declare-option -hidden str mt_dark_blue      'rgba:304A68'
declare-option -hidden str mt_cyan           'rgba:5CBE97'
declare-option -hidden str mt_cyan_bright    'rgba:A0C4BD'
declare-option -hidden str mt_gray           'rgba:A0A4AA'
declare-option -hidden str mt_gray_darker    'rgba:30343C'
declare-option -hidden str mt_gray_darkest   'rgba:1E2227'
declare-option -hidden str mt_green          'rgba:8BBE67'
declare-option -hidden str mt_green_bright   'rgba:B1C6AC'
declare-option -hidden str mt_magenta        'rgba:8B5FC7'
declare-option -hidden str mt_magenta_bright 'rgba:B1A3DF'
declare-option -hidden str mt_red            'rgba:E07093'
declare-option -hidden str mt_red_bright     'rgba:DFB4C9'
declare-option -hidden str mt_white          'rgba:D9D9D9'
declare-option -hidden str mt_white_bright   'rgba:FFFFFF'
declare-option -hidden str mt_yellow         'rgba:BB8E67'
declare-option -hidden str mt_yellow_bright  'rgba:C3B470'

# Code
set-face global value     "%opt{mt_red}FF"
set-face global type      "%opt{mt_magenta}FF"
set-face global variable  "%opt{mt_cyan}FF"
set-face global module    "%opt{mt_green_bright}FF"
set-face global function  "%opt{mt_magenta_bright}FF"
set-face global string    "%opt{mt_green}FF"
set-face global keyword   "%opt{mt_blue}FF"
set-face global operator  "%opt{mt_blue}FF"
set-face global attribute "%opt{mt_yellow}FF"
set-face global comment   "%opt{mt_gray}FF"
set-face global meta      "%opt{mt_green_bright}FF"
set-face global builtin   "%opt{mt_magenta_bright}FF"

# Markup
set-face global title  "%opt{mt_blue}FF"
set-face global header "%opt{mt_cyan}FF"
set-face global mono   "%opt{mt_green}FF"
set-face global block  "%opt{mt_magenta}FF"
set-face global link   "%opt{mt_cyan}FF"
set-face global bullet "%opt{mt_cyan}FF"
set-face global list   "%opt{mt_yellow}FF"

# Builtin faces
set-face global Default            "%opt{mt_white}FF,default"

set-face global Information        "default,%opt{mt_gray_darker}FF@Default"
set-face global Error              "%opt{mt_red}FF+b@Default"

set-face global MatchingChar       "+b"
set-face global Whitespace         "%opt{mt_black}FF+d"
set-face global BufferPadding      "%opt{mt_gray}FF"
set-face global WrapMarker         "%opt{mt_gray}FF+f"

set-face global LineNumbers        "%opt{mt_gray}FF@Default"
set-face global LineNumberCursor   "+b@LineNumbers"
set-face global LineNumbersWrapped "+d@LineNumbers"

set-face global MenuForeground     "%opt{mt_blue}FF,default+b@MenuBackground"
set-face global MenuBackground     "default,%opt{mt_gray_darker}FF@Default"
set-face global MenuInfo           "+i"

set-face global StatusLine         "@Default"
set-face global StatusLineMode     "%opt{mt_yellow}FF@Default"
set-face global StatusLineInfo     "%opt{mt_blue}FF@Default"
set-face global StatusLineValue    "%opt{mt_green}FF@Default"
set-face global StatusCursor       "%opt{mt_gray_darkest}FF,%opt{mt_cyan}FF"
set-face global Prompt             "%opt{mt_yellow}FF"

set-face global PrimarySelection   "%opt{mt_white}80,rgba:49719EFF+g"
set-face global SecondarySelection "%opt{mt_white}66,rgba:304A68FF+g"
set-face global PrimaryCursor      "%opt{mt_gray_darkest}FF,%opt{mt_white}FF+fg"

set-face global SecondaryCursor    "%opt{mt_gray_darkest}FF,%opt{mt_gray}FF+fg"
set-face global PrimaryCursorEol   "%opt{mt_gray_darkest}FF,%opt{mt_magenta_bright}FF+fg"
set-face global SecondaryCursorEol "%opt{mt_gray_darkest}FF,%opt{mt_magenta}FF+fg"
