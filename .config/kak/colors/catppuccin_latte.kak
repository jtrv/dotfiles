# Catppuccin theme for Kakoune

# Color palette
declare-option  -hidden str rosewater "rgba:dc8a78" # rgb:dc8a78
declare-option  -hidden str flamingo  "rgba:dd7878" # rgb:dd7878
declare-option  -hidden str pink      "rgba:ea76cb" # rgb:ea76cb
declare-option  -hidden str mauve     "rgba:8839ef" # rgb:8839ef
declare-option  -hidden str red       "rgba:d20f39" # rgb:d20f39
declare-option  -hidden str maroon    "rgba:e64553" # rgb:e64553
declare-option  -hidden str peach     "rgba:fe640b" # rgb:fe640b
declare-option  -hidden str yellow    "rgba:df8e1d" # rgb:df8e1d
declare-option  -hidden str green     "rgba:40a02b" # rgb:40a02b
declare-option  -hidden str teal      "rgba:179299" # rgb:179299
declare-option  -hidden str sky       "rgba:04a5e5" # rgb:04a5e5
declare-option  -hidden str sapphire  "rgba:209fb5" # rgb:209fb5
declare-option  -hidden str blue      "rgba:1e66f5" # rgb:1e66f5
declare-option  -hidden str lavender  "rgba:7287fd" # rgb:7287fd
declare-option  -hidden str text      "rgba:4c4f69" # rgb:4c4f69
declare-option  -hidden str subtext1  "rgba:5c5f77" # rgb:5c5f77
declare-option  -hidden str subtext0  "rgba:6c6f85" # rgb:6c6f85
declare-option  -hidden str overlay2  "rgba:7c7f93" # rgb:7c7f93
declare-option  -hidden str overlay1  "rgba:8c8fa1" # rgb:8c8fa1
declare-option  -hidden str overlay0  "rgba:9ca0b0" # rgb:9ca0b0
declare-option  -hidden str surface2  "rgba:acb0be" # rgb:acb0be
declare-option  -hidden str surface1  "rgba:bcc0cc" # rgb:bcc0cc
declare-option  -hidden str surface0  "rgba:ccd0da" # rgb:ccd0da
declare-option  -hidden str base      "rgba:eff1f5" # rgb:eff1f5
declare-option  -hidden str mantle    "rgba:e6e9ef" # rgb:e6e9ef
declare-option  -hidden str crust     "rgba:dce0e8" # rgb:dce0e8

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
set-face global BufferPadding      "%opt{background},%opt{crust}ff"
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
set-face global WhitespaceIndent   "%opt{surface0}ff,default+f"

# latte deviation: mocha uses %opt{background} / %opt{surface2} as the cursor
# foregrounds — near-black there, near-white here, so the pure palette swap left
# the main cursor at 2.17 contrast. Dark/light foregrounds picked per accent.
set-face global PrimaryCursorEol   "%opt{base}ff,%opt{mauve}ff"
set-face global PrimaryCursor      "%opt{text}ff,%opt{rosewater}ff"
set-face global PrimarySelection   "default,%opt{lavender}4d"

set-face global SecondaryCursorEol "%opt{base}ff,%opt{maroon}ff"
set-face global SecondaryCursor    "%opt{text}ff,%opt{teal}cc"
set-face global SecondarySelection "default,%opt{lavender}1f"

# Switching to normal = lavender/green
hook global ModeChange ".*:normal" %{
  set-face global StatusLineInfo "%opt{background},%opt{green}ff"
  set-face global StatusLineMode "%opt{background},%opt{lavender}ff"
  set-face global StatusLine     "%opt{lavender}ff,%opt{mantle}ff"
}

# Switching to insert = red/mauve
# (latte deviation: mocha uses peach here, but latte's peach #fe640b carries
#  only 2.45 contrast against the near-white statusline text; red gives 4.46)
hook global ModeChange ".*:insert" %{
  set-face global StatusLineInfo "%opt{background},%opt{mauve}ff"
  set-face global StatusLineMode "%opt{background},%opt{red}ff"
  set-face global StatusLine     "%opt{red}ff,%opt{mantle}ff"
}

# LSP

# Faces used by inlay diagnostics.
set-face global InlayDiagnosticError           "%opt{red}ff,%opt{background}"
set-face global InlayDiagnosticHint            "%opt{lavender}ff,%opt{background}"
set-face global InlayDiagnosticInfo            "%opt{sky}ff,%opt{background}+d"
set-face global InlayDiagnosticWarning         "%opt{peach}ff,%opt{background}"
# Faces used by inline diagnostics.
set-face global DiagnosticError                default,+c@InlayDiagnosticError
set-face global DiagnosticHint                 +u@InlayDiagnosticHint
set-face global DiagnosticInfo                 InlayDiagnosticInfo
set-face global DiagnosticWarning              +U@InlayDiagnosticWarning
set-face global DiagnosticTagDeprecated        +s
set-face global DiagnosticTagUnnecessary       +cs
# Faces used by line flags
set-face global LineFlagError                  "%opt{red}ff,%opt{background}"
set-face global LineFlagHint                   default
set-face global LineFlagInfo                   default
set-face global LineFlagWarning                "%opt{yellow}ff,%opt{background}"
# Face for highlighting references.
set-face global ReferenceBind                  "default,%opt{surface0}ff+bu"
set-face global Reference                      "default,%opt{surface0}ff"
# Face for inlay hints.
set-face global InlayHint                      "%opt{overlay0}ff,%opt{background}"
set-face global InlayCodeLens                  "%opt{overlay0}ff,%opt{background}"
# Faces used for hover info
set-face global InfoDefault                    "%opt{text}ff,%opt{surface1}ff+b"
set-face global InfoBlock                      "%opt{sapphire}ff,%opt{surface1}ff+b"
set-face global InfoBlockQuote                 "%opt{green}ff,%opt{surface1}ff+b"
set-face global InfoBullet                     "%opt{green}ff,%opt{surface1}ff+b"
set-face global InfoHeader                     "%opt{red}ff,%opt{surface1}ff+bu"
set-face global InfoLink                       "%opt{green}ff,%opt{surface1}ff+bi"
set-face global InfoLinkMono                   "%opt{green}ff,%opt{surface1}ff+bi"
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

# kak-rainbow-rs — the plugin's defaults are hardcoded RainbowBrackets hues plus
# a mocha-mantle scope background, so they have to follow the flavor too.
# `try` keeps the colorscheme loadable when the plugin isn't present.
try %{
  set-option global rainbow_colors            rgb:fe640b rgb:df8e1d rgb:40a02b rgb:04a5e5 rgb:1e66f5 rgb:8839ef
  set-option global background_rainbow_colors rgb:f1e0d9 rgb:ede5db rgb:dae7dc rgb:d2e8f3 rgb:d6e0f5 rgb:e2dbf4
  set-option global rainbow_cursor_scope_color "rgb:e6e9ef"
}


