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

# Switching to normal = blue/lavender/green
hook global ModeChange ".*:normal" %{
  set-face global StatusLineInfo "%opt{background},%opt{green}ff"
  set-face global StatusLineMode "%opt{background},%opt{lavender}ff"
  set-face global StatusLine     "%opt{lavender}ff,%opt{mantle}ff"
}

# Switching to insert = red/peach/yellow
hook global ModeChange ".*:insert" %{
  set-face global StatusLineInfo "%opt{background},%opt{mauve}ff"
  set-face global StatusLineMode "%opt{background},%opt{peach}ff"
  set-face global StatusLine     "%opt{peach}ff,%opt{mantle}ff"
}

# LSP
set-face global DiagnosticError                "%opt{red}ff,%opt{background}"
set-face global DiagnosticHint                 "%opt{lavender}ff,%opt{background}"
set-face global DiagnosticInfo                 "%opt{sky}ff,%opt{background}"
set-face global DiagnosticWarning              "%opt{peach}ff,%opt{background}"
set-face global InlayHint                      "%opt{overlay0}ff,%opt{background}"
set-face global LineFlagErrors                 "%opt{red}ff,%opt{background}"
set-face global LSPDiagnosticsUnderlineError   "%opt{red}ff+u"
set-face global LSPDiagnosticsUnderlineHint    "%opt{lavender}ff+u"
set-face global LSPDiagnosticsUnderlineInfo    "%opt{sky}ff+u"
set-face global LSPDiagnosticsUnderlineWarning "%opt{peach}ff+u"
set-face global ReferenceBind                  "default,%opt{surface0}ff+Fbu"
set-face global Reference                      "default,%opt{surface0}ff+F"
