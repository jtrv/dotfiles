# Catppuccin theme for Kakoune

# Color palette
declare-option  -hidden str rosewater "rgba:f5e0dc"
declare-option  -hidden str flamingo  "rgba:f2cdcd"
declare-option  -hidden str pink      "rgba:f5c2e7"
declare-option  -hidden str mauve     "rgba:cba6f7"
declare-option  -hidden str red       "rgba:f38ba8"
declare-option  -hidden str maroon    "rgba:eba0ac"
declare-option  -hidden str peach     "rgba:fab387"
declare-option  -hidden str yellow    "rgba:f9e2af"
declare-option  -hidden str green     "rgba:a6e3a1"
declare-option  -hidden str teal      "rgba:94e2d5"
declare-option  -hidden str sky       "rgba:89dceb"
declare-option  -hidden str sapphire  "rgba:74c7ec"
declare-option  -hidden str blue      "rgba:89b4fa"
declare-option  -hidden str lavender  "rgba:b4befe"
declare-option  -hidden str text      "rgba:cdd6f4"
declare-option  -hidden str subtext1  "rgba:bac2de"
declare-option  -hidden str subtext0  "rgba:a6adc8"
declare-option  -hidden str overlay2  "rgba:9399b2"
declare-option  -hidden str overlay1  "rgba:7f849c"
declare-option  -hidden str overlay0  "rgba:6c7086"
declare-option  -hidden str surface2  "rgba:585b70"
declare-option  -hidden str surface1  "rgba:45475a"
declare-option  -hidden str surface0  "rgba:313244"
declare-option  -hidden str base      "rgba:1e1e2e"
declare-option  -hidden str mantle    "rgba:181825"
declare-option  -hidden str crust     "rgba:11111b"

declare-option  -hidden str background "%opt{mantle}ff"
declare-option  -hidden str foreground "%opt{text}ff"

# Markup
set-face global block  "%opt{sapphire}ff"
set-face global bold   "%opt{mauve}ff"
set-face global bullet "%opt{green}ff"
set-face global header "%opt{red}ff"
set-face global italic "%opt{lavender}ff"
set-face global link   "%opt{green}ff"
set-face global list   "%opt{text}ff"
set-face global mono   "%opt{green}ff"
set-face global title  "%opt{rosewater}ff"

# Code
set-face global attribute     "%opt{green}ff"
set-face global builtin       "%opt{lavender}ff+b"
set-face global comment       "%opt{overlay0}ff"
set-face global documentation comment
set-face global function      "%opt{sky}ff"
set-face global keyword       "%opt{blue}ff"
set-face global meta          "%opt{pink}ff"
set-face global module        "%opt{maroon}ff"
set-face global operator      "%opt{blue}ff"
set-face global string        "%opt{green}ff"
set-face global type          "%opt{rosewater}ff"
set-face global value         "%opt{peach}ff"
set-face global variable      "%opt{text}ff"

# Builtins
set-face global BufferPadding      "%opt{background},%opt{background}"
set-face global Default            "%opt{text}ff,%opt{background}"
set-face global Error              "%opt{red}ff,%opt{base}ff"
set-face global Information        "%opt{text}ff,%opt{surface1}ff+b"
set-face global LineNumberCursor   "%opt{lavender}ff,%opt{surface2}ff+b"
set-face global LineNumbers        "%opt{overlay0}ff,%opt{background}"
set-face global LineNumbersWrapped "%opt{teal}ff,%opt{mantle}ff+i"
set-face global MatchingChar       "%opt{maroon}ff,%opt{base}ff"
set-face global MenuBackground     "%opt{text}ff,%opt{surface0}ff"
set-face global MenuForeground     "%opt{text}ff,%opt{surface2}ff+b"
set-face global MenuInfo           "%opt{mantle}ff,%opt{blue}ff"
set-face global Prompt             "%opt{green}ff,%opt{base}ff"
set-face global StatusCursor       "%opt{mantle}ff,%opt{lavender}ff"
set-face global StatusLineInfo     "%opt{background},%opt{green}ff"
set-face global StatusLineMode     "%opt{base}ff,%opt{yellow}ff"
set-face global StatusLine         "%opt{lavender}ff,%opt{mantle}ff"
set-face global Whitespace         "%opt{overlay0}ff,%opt{background}+f"
set-face global WrapMarker         Whitespace

set-face global PrimaryCursorEol   "%opt{surface2}ff,%opt{mauve}ff"
set-face global PrimaryCursor      "%opt{background},%opt{rosewater}ff"
set-face global PrimarySelection   "default,%opt{lavender}4d"

set-face global SecondaryCursorEol "%opt{surface2}ff,%opt{maroon}ff"
set-face global SecondaryCursor    "%opt{mantle}ff,%opt{teal}cc"
set-face global SecondarySelection "default,%opt{lavender}1f"

# Switching to normal = lavender/green
hook global ModeChange ".*:normal" %{
  set-face global StatusLineInfo "%opt{background},%opt{green}ff"
  set-face global StatusLineMode "%opt{background},%opt{lavender}ff"
  set-face global StatusLine     "%opt{lavender}ff,%opt{mantle}ff"
}

# Switching to insert = peach/mauve
hook global ModeChange ".*:insert" %{
  set-face global StatusLineInfo "%opt{background},%opt{mauve}ff"
  set-face global StatusLineMode "%opt{background},%opt{peach}ff"
  set-face global StatusLine     "%opt{peach}ff,%opt{mantle}ff"
}

# LSP

# Faces used by inline diagnostics.
set-face global DiagnosticError                "%opt{red}ff,%opt{background}+c"
set-face global DiagnosticHint                 "%opt{lavender}ff,%opt{background}+u"
set-face global DiagnosticInfo                 "%opt{sky}ff,%opt{background}"
set-face global DiagnosticWarning              "%opt{peach}ff,%opt{background}+U"
set-face global DiagnosticTagDeprecated        +s
set-face global DiagnosticTagUnnecessary       +d
# Faces used by inlay diagnostics.
set-face global InlayDiagnosticError           DiagnosticError
set-face global InlayDiagnosticHint            DiagnosticHint
set-face global InlayDiagnosticInfo            DiagnosticInfo
set-face global InlayDiagnosticWarning         DiagnosticWarning
# Faces used by line flags
set-face global LineFlagError                  "%opt{red}ff,%opt{background}"
set-face global LineFlagHint                   default
set-face global LineFlagInfo                   default
set-face global LineFlagWarning                yellow
# Face for highlighting references.
set-face global ReferenceBind                  "default,%opt{surface0}ff+bu"
set-face global Reference                      "default,%opt{surface0}ff"
# Face for inlay hints.
set-face global InlayHint                      "%opt{overlay0}ff,%opt{background}"
set-face global InlayCodeLens                  cyan+d
# Faces used for hover info
set-face global InfoDefault                    "%opt{text}ff,%opt{surface1}ff+b"
set-face global InfoBlock                      "%opt{sapphire}ff,%opt{surface1}ff+b"
set-face global InfoBlockQuote                 "%opt{green}ff,%opt{surface1}ff+b"
set-face global InfoBullet                     "%opt{green}ff,%opt{surface1}ff+b"
set-face global InfoHeader                     "%opt{red}ff,%opt{surface1}ff+b"
set-face global InfoLink                       "%opt{green}ff,%opt{surface1}ff+b"
set-face global InfoLinkMono                   "%opt{green}ff,%opt{surface1}ff+b"
set-face global InfoMono                       "%opt{green}ff,%opt{surface1}ff+b"
set-face global InfoRule                       "%opt{text}ff,%opt{surface1}ff+b"
set-face global InfoDiagnosticError            "%opt{red}ff,%opt{surface1}ff+b"
set-face global InfoDiagnosticHint             "%opt{lavender}ff,%opt{surface1}ff+b"
set-face global InfoDiagnosticInformation      "%opt{sky}ff,%opt{surface1}ff+b"
set-face global InfoDiagnosticWarning          "%opt{peach}ff,%opt{surface1}ff+b"

# Tree-Sitter
set-face global ts_attribute                    "%opt{blue}ff"
set-face global ts_comment                      "%opt{overlay0}ff+i"
set-face global ts_conceal                      "%opt{mauve}ff+i"
set-face global ts_constant                     "%opt{peach}ff"
set-face global ts_constant_builtin_boolean     "%opt{sky}ff"
set-face global ts_constant_character           "%opt{yellow}ff"
set-face global ts_constant_macro               "%opt{mauve}ff"
set-face global ts_constructor                  "%opt{sapphire}ff"
set-face global ts_diff_plus                    "%opt{green}ff"
set-face global ts_diff_minus                   "%opt{red}ff"
set-face global ts_diff_delta                   "%opt{blue}ff"
set-face global ts_diff_delta_moved             "%opt{mauve}ff"
set-face global ts_error                        "%opt{red}ff+b"
set-face global ts_function                     "%opt{blue}ff"
set-face global ts_function_builtin             "%opt{blue}ff+i"
set-face global ts_function_macro               "%opt{mauve}ff"
set-face global ts_hint                         "%opt{blue}ff+b"
set-face global ts_info                         "%opt{green}ff+b"
set-face global ts_keyword                      "%opt{mauve}ff"
set-face global ts_keyword_conditional          "%opt{mauve}ff+i"
set-face global ts_keyword_control_conditional  "%opt{mauve}ff+i"
set-face global ts_keyword_control_directive    "%opt{mauve}ff+i"
set-face global ts_keyword_control_import       "%opt{mauve}ff+i"
set-face global ts_keyword_directive            "%opt{mauve}ff+i"
set-face global ts_label                        "%opt{sapphire}ff+i"
set-face global ts_markup_bold                  "%opt{peach}ff+b"
set-face global ts_markup_heading               "%opt{red}ff"
set-face global ts_markup_heading_1             "%opt{red}ff"
set-face global ts_markup_heading_2             "%opt{mauve}ff"
set-face global ts_markup_heading_3             "%opt{green}ff"
set-face global ts_markup_heading_4             "%opt{yellow}ff"
set-face global ts_markup_heading_5             "%opt{pink}ff"
set-face global ts_markup_heading_6             "%opt{sapphire}ff"
set-face global ts_markup_heading_marker        "%opt{peach}ff+b"
set-face global ts_markup_italic                "%opt{pink}ff+i"
set-face global ts_markup_list_checked          "%opt{green}ff"
set-face global ts_markup_list_numbered         "%opt{blue}ff+i"
set-face global ts_markup_list_unchecked        "%opt{sapphire}ff"
set-face global ts_markup_list_unnumbered       "%opt{mauve}ff"
set-face global ts_markup_link_label            "%opt{blue}ff"
set-face global ts_markup_link_url              "%opt{sapphire}ff+u"
set-face global ts_markup_link_uri              "%opt{sapphire}ff+u"
set-face global ts_markup_link_text             "%opt{blue}ff"
set-face global ts_markup_quote                 "%opt{subtext0}ff"
set-face global ts_markup_raw                   "%opt{green}ff"
set-face global ts_markup_strikethrough         "%opt{subtext0}ff+s"
set-face global ts_namespace                    "%opt{blue}ff+i"
set-face global ts_operator                     "%opt{sky}ff"
set-face global ts_property                     "%opt{sky}ff"
set-face global ts_punctuation                  "%opt{overlay1}ff"
set-face global ts_punctuation_special          "%opt{sky}ff"
set-face global ts_special                      "%opt{blue}ff"
set-face global ts_spell                        "%opt{mauve}ff"
set-face global ts_string                       "%opt{green}ff"
set-face global ts_string_regex                 "%opt{peach}ff"
set-face global ts_string_regexp                "%opt{peach}ff"
set-face global ts_string_escape                "%opt{mauve}ff"
set-face global ts_string_special               "%opt{blue}ff"
set-face global ts_string_special_path          "%opt{green}ff"
set-face global ts_string_special_symbol        "%opt{mauve}ff"
set-face global ts_string_symbol                "%opt{red}ff"
set-face global ts_tag                          "%opt{mauve}ff"
set-face global ts_tag_error                    "%opt{red}ff"
set-face global ts_text                         "%opt{text}ff"
set-face global ts_text_title                   "%opt{mauve}ff"
set-face global ts_type                         "%opt{yellow}ff"
set-face global ts_type_enum_variant            "%opt{flamingo}ff"
set-face global ts_variable                     "%opt{text}ff"
set-face global ts_variable_builtin             "%opt{red}ff"
set-face global ts_variable_other_member        "%opt{sapphire}ff"
set-face global ts_variable_parameter           "%opt{maroon}ff+i"
set-face global ts_warning                      "%opt{peach}ff+b"


