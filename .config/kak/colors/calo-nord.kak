# Adapted from https://github.com/nojhan/kalolo

# This colorscheme takes the ideas of kalolo and makes the promptline
# more uniform, and also makes the colorscheme work with transparent
# terminals. The latter is mostly achieved by using rgba hex colors.
# I also added 50% opacity to the main cursor and 25% opacity to the
# secondary cursor to get the respective selection colors but this
# overlay for selections broke with the transparent background color.
# To get around this I used xcolor to pipette the composite of these
# translucent colors over the opaque background of normal kalolo.


# Colors

# Blues
declare-option -hidden str kalolo_shiny_blue    rgba:b7dbffff
declare-option -hidden str kalolo_light_blue    rgba:87bbffff
declare-option -hidden str kalolo_blue          rgba:6f9dfeff
declare-option -hidden str kalolo_dark_blue     rgba:4f7ddeff

# Magentas
declare-option -hidden str kalolo_light_magenta rgba:c6b3ffff
declare-option -hidden str kalolo_magenta       rgba:a073bbff

# Yellows
declare-option -hidden str kalolo_light_yellow  rgba:fffb95ff
declare-option -hidden str kalolo_mid_yellow    rgba:f5db65ff
declare-option -hidden str kalolo_yellow        rgba:efcd45ff
declare-option -hidden str kalolo_dark_yellow   rgba:cf8200ff

# Greens
declare-option -hidden str kalolo_shiny_green   rgba:b1cfb1ff
declare-option -hidden str kalolo_light_green   rgba:b5d271ff
declare-option -hidden str kalolo_green         rgba:a5c261ff
declare-option -hidden str kalolo_dark_green    rgba:529f50ff

# Reds
declare-option -hidden str kalolo_light_red     rgba:ff5949ff
declare-option -hidden str kalolo_red           rgba:db4939ff
declare-option -hidden str kalolo_dark_red      rgba:cb3929ff

# Orange-ish
declare-option -hidden str kalolo_cream         rgba:bf8753ff
declare-option -hidden str kalolo_dark_cream    rgba:363037ff

# Whites
declare-option -hidden str kalolo_light_white   rgba:f8f8f8ff
declare-option -hidden str kalolo_white         rgba:d3d0ccff
declare-option -hidden str kalolo_mid_white     rgba:b1bfb1ff
declare-option -hidden str kalolo_dark_white    rgba:73707cff

# Blacks
declare-option -hidden str kalolo_light_black   rgba:4b4b4bff
declare-option -hidden str kalolo_mid_black     rgba:343534ff
declare-option -hidden str kalolo_black         rgba:2b2b2b12
declare-option -hidden str kalolo_dawn_black    rgba:232323ff
declare-option -hidden str kalolo_dark_black    rgba:000000ff


# Code

# Comment are important information, they are the only thing in light green.
set-face global comment            "%opt{kalolo_green},default"
# Documentation is even more important, it's in bold.
set-face global documentation      "%opt{kalolo_green},default+b"
# Metadata are less important, they are in dark green.
set-face global meta               "%opt{kalolo_mid_white},%opt{kalolo_dawn_black}"
# Values are a kind of "side" information, they are in dark green.
set-face global value              "%opt{kalolo_dark_green},default"

# "Stable" objects in blue.
set-face global identifier         "%opt{kalolo_blue},default"
set-face global type               "%opt{kalolo_light_blue},default"
set-face global entity             "%opt{kalolo_magenta},default+b"

# "Mutable" objects in blue.
set-face global variable           "%opt{kalolo_white},default"
set-face global module             "%opt{kalolo_dark_blue},default"

# String are ubiquitous, they have their own color,
# with a different background, to easily spot multiline strings.
# set-face global string             "%opt{kalolo_cream},%opt{kalolo_dark_cream}"
set-face global string             "%opt{kalolo_shiny_green},%opt{kalolo_mid_black}"

# More or less single-character delimiter which are everywhere.
set-face global operator           "%opt{kalolo_light_magenta},default"
set-face global delimiter          "%opt{kalolo_light_yellow},default"

# Attributes in yellow.
set-face global attribute          "%opt{kalolo_yellow},default"

# Builtins in lighter white.
set-face global builtin            "%opt{kalolo_light_white},default"

# Generic keywords in red.
set-face global keyword            "%opt{kalolo_red},default"
# Additional keywords
set-face global flow               "%opt{kalolo_red},default+b" # Keywords related to control flow (if,for,assert,etc.).
set-face global state              "%opt{kalolo_red},default"   # Keywords reated to state (cast,new,sizeof,etc.).


# tree-sitter faces

set-face global ts_attribute                    "%opt{kalolo_light_blue}"
set-face global ts_comment                      "%opt{kalolo_green}+i"
set-face global ts_comment_block                "ts_comment"
set-face global ts_comment_line                 "ts_comment"
set-face global ts_conceal                      "%opt{kalolo_light_magenta}+i"
set-face global ts_constant                     "%opt{kalolo_cream}"
set-face global ts_constant_builtin_boolean     "%opt{kalolo_shiny_blue}"
set-face global ts_constant_character           "%opt{kalolo_light_yellow}"
set-face global ts_constant_character_escape    "ts_constant_character"
set-face global ts_constant_macro               "%opt{kalolo_light_magenta}"
set-face global ts_constant_numeric             "%opt{kalolo_cream}"
set-face global ts_constant_numeric_float       "ts_constant_numeric"
set-face global ts_constant_numeric_integer     "ts_constant_numeric"
set-face global ts_constructor                  "%opt{kalolo_shiny_blue}"
set-face global ts_diff_plus                    "%opt{kalolo_green}"
set-face global ts_diff_minus                   "%opt{kalolo_red}"
set-face global ts_diff_delta                   "%opt{kalolo_blue}"
set-face global ts_diff_delta_moved             "%opt{kalolo_light_magenta}"
set-face global ts_error                        "%opt{kalolo_red}+b"
set-face global ts_function                     "%opt{kalolo_blue}"
set-face global ts_function_builtin             "%opt{kalolo_blue}+i"
set-face global ts_function_macro               "%opt{kalolo_light_magenta}"
set-face global ts_function_method              "ts_function"
set-face global ts_function_special             "ts_function"
set-face global ts_hint                         "%opt{kalolo_light_blue}+b"
set-face global ts_info                         "%opt{kalolo_light_green}+b"
set-face global ts_keyword                      "%opt{kalolo_light_magenta}"
set-face global ts_keyword_control              "ts_keyword"
set-face global ts_keyword_conditional          "%opt{kalolo_light_magenta}+i"
set-face global ts_keyword_control_conditional  "%opt{kalolo_light_magenta}+i"
set-face global ts_keyword_control_directive    "%opt{kalolo_light_magenta}+i"
set-face global ts_keyword_control_import       "%opt{kalolo_light_magenta}+i"
set-face global ts_keyword_control_repeat       "ts_keyword"
set-face global ts_keyword_control_return       "ts_keyword"
set-face global ts_keyword_control_except       "ts_keyword"
set-face global ts_keyword_control_exception    "ts_keyword"
set-face global ts_keyword_directive            "%opt{kalolo_light_magenta}+i"
set-face global ts_keyword_function             "ts_keyword"
set-face global ts_keyword_operator             "ts_keyword"
set-face global ts_keyword_special              "ts_keyword"
set-face global ts_keyword_storage              "ts_keyword"
set-face global ts_keyword_storage_modifier     "ts_keyword"
set-face global ts_keyword_storage_modifier_mut "ts_keyword"
set-face global ts_keyword_storage_modifier_ref "ts_keyword"
set-face global ts_keyword_storage_type         "ts_keyword"
set-face global ts_label                        "%opt{kalolo_shiny_blue}+i"
set-face global ts_markup_bold                  "%opt{kalolo_cream}+b"
set-face global ts_markup_heading               "%opt{kalolo_red}"
set-face global ts_markup_heading_1             "%opt{kalolo_red}"
set-face global ts_markup_heading_2             "%opt{kalolo_light_magenta}"
set-face global ts_markup_heading_3             "%opt{kalolo_light_green}"
set-face global ts_markup_heading_4             "%opt{kalolo_light_yellow}"
set-face global ts_markup_heading_5             "%opt{kalolo_light_magenta}"
set-face global ts_markup_heading_6             "%opt{kalolo_blue}"
set-face global ts_markup_heading_marker        "%opt{kalolo_cream}+b"
set-face global ts_markup_italic                "%opt{kalolo_light_magenta}+i"
set-face global ts_markup_list_checked          "%opt{kalolo_green}"
set-face global ts_markup_list_numbered         "%opt{kalolo_blue}+i"
set-face global ts_markup_list_unchecked        "%opt{kalolo_blue}"
set-face global ts_markup_list_unnumbered       "%opt{kalolo_light_magenta}"
set-face global ts_markup_link_label            "%opt{kalolo_blue}"
set-face global ts_markup_link_url              "%opt{kalolo_blue}+u"
set-face global ts_markup_link_uri              "%opt{kalolo_blue}+u"
set-face global ts_markup_link_text             "%opt{kalolo_blue}"
set-face global ts_markup_quote                 "%opt{kalolo_mid_white}"
set-face global ts_markup_raw                   "%opt{kalolo_light_green}"
set-face global ts_markup_raw_block             "%opt{kalolo_light_green}"
set-face global ts_markup_raw_inline            "%opt{kalolo_light_green}"
set-face global ts_markup_strikethrough         "%opt{kalolo_mid_white}+s"
set-face global ts_namespace                    "%opt{kalolo_blue}+i"
set-face global ts_operator                     "%opt{kalolo_light_blue}"
set-face global ts_property                     "%opt{kalolo_light_blue}"
set-face global ts_punctuation                  "%opt{kalolo_light_yellow}"
set-face global ts_punctuation_bracket          "ts_punctuation"
set-face global ts_punctuation_delimiter        "ts_punctuation"
set-face global ts_punctuation_special          "%opt{kalolo_light_blue}"
set-face global ts_special                      "%opt{kalolo_blue}"
set-face global ts_spell                        "%opt{kalolo_light_magenta}"
set-face global ts_string                       "%opt{kalolo_shiny_green}"
set-face global ts_string_regex                 "%opt{kalolo_cream}"
set-face global ts_string_regexp                "%opt{kalolo_cream}"
set-face global ts_string_escape                "%opt{kalolo_light_magenta}"
set-face global ts_string_special               "%opt{kalolo_blue}"
set-face global ts_string_special_path          "%opt{kalolo_light_green}"
set-face global ts_string_special_symbol        "%opt{kalolo_light_magenta}"
set-face global ts_string_symbol                "%opt{kalolo_red}"
set-face global ts_tag                          "%opt{kalolo_light_magenta}"
set-face global ts_tag_error                    "%opt{kalolo_red}"
set-face global ts_text                         "%opt{kalolo_white}"
set-face global ts_text_title                   "%opt{kalolo_light_magenta}"
set-face global ts_type                         "%opt{kalolo_light_yellow}"
set-face global ts_type_builtin                 "ts_type"
set-face global ts_type_enum_variant            "%opt{kalolo_cream}"
set-face global ts_variable                     "%opt{kalolo_white}"
set-face global ts_variable_builtin             "%opt{kalolo_red}"
set-face global ts_variable_other_member        "%opt{kalolo_blue}"
set-face global ts_variable_parameter           "%opt{kalolo_red}+i"
set-face global ts_warning                      "%opt{kalolo_light_yellow}+b"


# LSP faces

# Additionnal "function"
set-face global function           "%opt{kalolo_light_white},default"

# Faces used by inline diagnostics.
set-face global DiagnosticError    "rgba:ff0000ff,default"
set-face global DiagnosticWarning  "rgba:ff00ffff,default"
# Faces used by inlay diagnostics.
set-face global InlayDiagnosticError   "rgba:ff00ffff,default+i"
set-face global InlayDiagnosticWarning "rgba:ff00ffff,default+i"
# Line flags for errors and warnings both use this face.
set-face global LineFlagErrors red
# Face for highlighting references.
# FIXME Reference faces not taken into account
set-face global Reference          "default,%opt{kalolo_light_black}+F"
set-face global ReferenceBind      "default,%opt{kalolo_light_black}+Fbu"
# Face for inlay hints.
set-face global InlayHint          "%opt{kalolo_light_white},default+i"

# text
set-face global title              "%opt{kalolo_light_blue},default+bi"
set-face global header             "%opt{kalolo_light_magenta},default+bu"
set-face global bold               "%opt{kalolo_light_yellow},default+b"
set-face global italic             "%opt{kalolo_light_white},default+i"
set-face global mono               "%opt{kalolo_white},%opt{kalolo_dawn_black}"
set-face global block              "%opt{kalolo_light_green},default"
set-face global link               "%opt{kalolo_dark_blue},default+u"
set-face global bullet             "%opt{kalolo_yellow},default+b"
set-face global list               "%opt{kalolo_light_white},default"

# kakoune UI
set-face global Default            "%opt{kalolo_white},default"
set-face global MatchingChar       "%opt{kalolo_light_white},%opt{kalolo_dark_green}"
set-face global Whitespace         "%opt{kalolo_dark_white},default"
set-face global BufferPadding      "%opt{kalolo_light_black},%opt{kalolo_dark_black}"
set-face global LineNumbers        "%opt{kalolo_dark_white},default"
set-face global LineNumberCursor   "%opt{kalolo_light_white},default"
set-face global LineNumbersWrapped "%opt(kalolo_dark_black)"
set-face global MenuForeground     "%opt{kalolo_light_white},%opt{kalolo_dark_yellow}+b"
set-face global MenuBackground     "%opt{kalolo_light_white},%opt{kalolo_dark_blue}"
set-face global MenuInfo           "%opt{kalolo_light_white},%opt{kalolo_blue}+i"
set-face global Error              "%opt{kalolo_light_yellow},%opt{kalolo_red}"

# Additional UI
# Like a temporary comment: light green.
set-face global Search             "%opt{kalolo_black},%opt{kalolo_light_green}+i"

##### Default normal #####
# Cursors varying with mode
set-face global PrimarySelection   "default,rgba:765217ff"
set-face global PrimaryCursor      "%opt{kalolo_black},%opt{kalolo_light_yellow}+F"
set-face global PrimaryCursorEol   "default,%opt{kalolo_light_red}+F"

set-face global SecondarySelection "default,rgba:57421fff"
set-face global SecondaryCursor    "%opt{kalolo_white},%opt{kalolo_dark_yellow}+F"
set-face global SecondaryCursorEol "default,%opt{kalolo_dark_red}+F"

# mode-dependent UI
set-face global StatusLine         "%opt{kalolo_dark_black},%opt{kalolo_yellow}"
set-face global StatusLineMode     "%opt{kalolo_dark_black},%opt{kalolo_yellow}"
set-face global StatusLineInfo     "%opt{kalolo_black},%opt{kalolo_yellow}+b"
set-face global StatusLineValue    "%opt{kalolo_black},%opt{kalolo_yellow}"
set-face global StatusCursor       "%opt{kalolo_black},%opt{kalolo_light_blue}"
set-face global Prompt             "%opt{kalolo_light_white},%opt{kalolo_dark_black}+b"
set-face global Information        "%opt{kalolo_light_white},%opt{kalolo_dark_blue}+b"

# Switching to normal = shades of yellows
hook global ModeChange '.*:normal' %{
    set-face global PrimarySelection   "default,rgba:765217ff"
    set-face global PrimaryCursor      "%opt{kalolo_black},%opt{kalolo_light_yellow}+F"
    set-face global PrimaryCursorEol   "default,%opt{kalolo_light_red}+F"

    set-face global SecondarySelection "default,rgba:57421fff"
    set-face global SecondaryCursor    "%opt{kalolo_white},%opt{kalolo_dark_yellow}+F"
    set-face global SecondaryCursorEol "default,%opt{kalolo_dark_red}+F"

    set-face global StatusLine         "%opt{kalolo_dark_black},%opt{kalolo_yellow}"
    set-face global StatusLineMode     "%opt{kalolo_dark_black},%opt{kalolo_yellow}"
    set-face global StatusLineInfo     "%opt{kalolo_black},%opt{kalolo_yellow}+b"
    set-face global StatusLineValue    "%opt{kalolo_black},%opt{kalolo_dark_black}"
    set-face global StatusCursor       "%opt{kalolo_black},%opt{kalolo_light_blue}"
    set-face global Prompt             "%opt{kalolo_light_white},%opt{kalolo_dark_black}+b"
    set-face global Information        "%opt{kalolo_black},%opt{kalolo_yellow}+b"
}

# Switching to insert = shades of blue
hook global ModeChange '.*:insert' %{
    set-face global PrimarySelection   "default,rgba:4a5f8bff"
    set-face global PrimaryCursor      "%opt{kalolo_dark_black},%opt{kalolo_light_blue}+F"
    set-face global PrimaryCursorEol   "default,%opt{kalolo_light_magenta}+F"

    set-face global SecondarySelection "default,rgba:3d4964ff"
    set-face global SecondaryCursor    "%opt{kalolo_light_white},%opt{kalolo_dark_blue}+F"
    set-face global SecondaryCursorEol "default,%opt{kalolo_magenta}+F"

    set-face global StatusLine         "%opt{kalolo_dark_black},%opt{kalolo_dark_blue}"
    set-face global StatusLineMode     "%opt{kalolo_light_white},%opt{kalolo_dark_blue}"
    set-face global StatusLineInfo     "%opt{kalolo_light_white},%opt{kalolo_dark_blue}+b"
    set-face global StatusLineValue    "%opt{kalolo_black},%opt{kalolo_dark_blue}"
    set-face global StatusCursor       "%opt{kalolo_light_white},%opt{kalolo_light_yellow}"
    set-face global Prompt             "%opt{kalolo_dark_black},%opt{kalolo_dark_black}+b"
    set-face global Information        "%opt{kalolo_light_white},%opt{kalolo_dark_blue}+b"
}
