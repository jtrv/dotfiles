# Catppuccin Mocha
#
# Base: https://github.com/catppuccin/kakoune (whiskers-generated, verbatim).
# Local additions, each marked below: LSP faces, tree-sitter faces, the
# mode-change statusline hooks, WhitespaceIndent, and kak-rainbow-rs colors.
# Keep the latte file in step -- it is this file with the palette swapped and
# its deviations marked.

evaluate-commands %sh{
    rosewater='rgb:f5e0dc'
    flamingo='rgb:f2cdcd'
    pink='rgb:f5c2e7'
    mauve='rgb:cba6f7'
    red='rgb:f38ba8'
    maroon='rgb:eba0ac'
    peach='rgb:fab387'
    yellow='rgb:f9e2af'
    green='rgb:a6e3a1'
    teal='rgb:94e2d5'
    sky='rgb:89dceb'
    sapphire='rgb:74c7ec'
    blue='rgb:89b4fa'
    lavender='rgb:b4befe'
    text='rgb:cdd6f4'
    subtext1='rgb:bac2de'
    subtext0='rgb:a6adc8'
    overlay2='rgb:9399b2'
    overlay1='rgb:7f849c'
    overlay0='rgb:6c7086'
    surface2='rgb:585b70'
    surface1='rgb:45475a'
    surface0='rgb:313244'
    base='rgb:1e1e2e'
    mantle='rgb:181825'
    crust='rgb:11111b'

    echo "
        # --- local: the palette as options too ---
        # kakrc's REasymotion faces and the espresso scheme reference
        # %opt{<colour>}ff, which upstream's shell-variable structure does not
        # provide. Emitted from the same variables so there is still one source
        # of truth per flavor. Re-declaring updates the value, so switching
        # flavors rewrites these rather than erroring.
        declare-option -hidden str rosewater rgba:${rosewater#rgb:}
        declare-option -hidden str flamingo  rgba:${flamingo#rgb:}
        declare-option -hidden str pink      rgba:${pink#rgb:}
        declare-option -hidden str mauve     rgba:${mauve#rgb:}
        declare-option -hidden str red       rgba:${red#rgb:}
        declare-option -hidden str maroon    rgba:${maroon#rgb:}
        declare-option -hidden str peach     rgba:${peach#rgb:}
        declare-option -hidden str yellow    rgba:${yellow#rgb:}
        declare-option -hidden str green     rgba:${green#rgb:}
        declare-option -hidden str teal      rgba:${teal#rgb:}
        declare-option -hidden str sky       rgba:${sky#rgb:}
        declare-option -hidden str sapphire  rgba:${sapphire#rgb:}
        declare-option -hidden str blue      rgba:${blue#rgb:}
        declare-option -hidden str lavender  rgba:${lavender#rgb:}
        declare-option -hidden str text      rgba:${text#rgb:}
        declare-option -hidden str subtext1  rgba:${subtext1#rgb:}
        declare-option -hidden str subtext0  rgba:${subtext0#rgb:}
        declare-option -hidden str overlay2  rgba:${overlay2#rgb:}
        declare-option -hidden str overlay1  rgba:${overlay1#rgb:}
        declare-option -hidden str overlay0  rgba:${overlay0#rgb:}
        declare-option -hidden str surface2  rgba:${surface2#rgb:}
        declare-option -hidden str surface1  rgba:${surface1#rgb:}
        declare-option -hidden str surface0  rgba:${surface0#rgb:}
        declare-option -hidden str base      rgba:${base#rgb:}
        declare-option -hidden str mantle    rgba:${mantle#rgb:}
        declare-option -hidden str crust     rgba:${crust#rgb:}

        set-face global title  ${text}+b
        set-face global header ${subtext0}+b
        set-face global bold   ${maroon}+b
        set-face global italic ${maroon}+i
        set-face global mono   ${green}
        set-face global block  ${sapphire}
        set-face global link   ${blue}
        set-face global bullet ${peach}
        set-face global list   ${peach}

        set-face global Default            ${text},${base}
        set-face global PrimarySelection   ${text},${surface2}
        set-face global SecondarySelection ${text},${surface2}
        set-face global PrimaryCursor      ${crust},${rosewater}
        set-face global SecondaryCursor    ${text},${overlay0}
        set-face global PrimaryCursorEol   ${surface2},${lavender}
        set-face global SecondaryCursorEol ${surface2},${overlay1}
        set-face global LineNumbers        ${overlay1},${base}
        set-face global LineNumberCursor   ${rosewater},${surface2}+b
        set-face global LineNumbersWrapped ${rosewater},${surface2}
        set-face global MenuForeground     ${text},${surface1}+b
        set-face global MenuBackground     ${text},${surface0}
        set-face global MenuInfo           ${crust},${teal}
        set-face global Information        ${crust},${teal}
        set-face global Error              ${crust},${red}
        set-face global StatusLine         ${text},${mantle}
        set-face global StatusLineMode     ${crust},${yellow}
        set-face global StatusLineInfo     ${crust},${teal}
        set-face global StatusLineValue    ${crust},${yellow}
        set-face global StatusCursor       ${crust},${rosewater}
        set-face global Prompt             ${teal},${base}+b
        set-face global MatchingChar       ${maroon},${base}
        set-face global Whitespace         ${overlay1},${base}+f
        set-face global WrapMarker         Whitespace
        set-face global BufferPadding      ${base},${base}

        set-face global value         ${peach}
        set-face global type          ${blue}
        set-face global variable      ${text}
        set-face global module        ${maroon}
        set-face global function      ${blue}
        set-face global string        ${green}
        set-face global keyword       ${mauve}
        set-face global operator      ${sky}
        set-face global attribute     ${green}
        set-face global comment       ${overlay0}
        set-face global documentation comment
        set-face global meta          ${yellow}
        set-face global builtin       ${red}

        # --- local: upstream has no indent guide face ---
        set-face global WhitespaceIndent ${surface0},default+f

        # --- local: kak-lsp ---
        set-face global InlayDiagnosticError      ${red},${base}
        set-face global InlayDiagnosticHint       ${lavender},${base}
        set-face global InlayDiagnosticInfo       ${sky},${base}+d
        set-face global InlayDiagnosticWarning    ${peach},${base}
        set-face global DiagnosticError           default,+c@InlayDiagnosticError
        set-face global DiagnosticHint            +u@InlayDiagnosticHint
        set-face global DiagnosticInfo            InlayDiagnosticInfo
        set-face global DiagnosticWarning         +U@InlayDiagnosticWarning
        set-face global DiagnosticTagDeprecated   +s
        set-face global DiagnosticTagUnnecessary  +cs
        set-face global LineFlagError             ${red},${base}
        set-face global LineFlagHint              default
        set-face global LineFlagInfo              default
        set-face global LineFlagWarning           ${yellow},${base}
        set-face global ReferenceBind             default,${surface0}+bu
        set-face global Reference                 default,${surface0}
        set-face global InlayHint                 ${overlay0},${base}
        set-face global InlayCodeLens             ${overlay0},${base}
        set-face global InfoDefault               ${text},${surface1}+b
        set-face global InfoBlock                 ${sapphire},${surface1}+b
        set-face global InfoBlockQuote            ${green},${surface1}+b
        set-face global InfoBullet                ${green},${surface1}+b
        set-face global InfoHeader                ${red},${surface1}+bu
        set-face global InfoLink                  ${green},${surface1}+bi
        set-face global InfoLinkMono              ${green},${surface1}+bi
        set-face global InfoMono                  ${green},${surface1}+b
        set-face global InfoRule                  ${text},${surface1}+b
        set-face global InfoDiagnosticError       ${red},${surface1}+b
        set-face global InfoDiagnosticHint        ${lavender},${surface1}+b
        set-face global InfoDiagnosticInformation ${sky},${surface1}+b
        set-face global InfoDiagnosticWarning     ${peach},${surface1}+b

        # --- local: tree-sitter ---
        set-face global ts_attribute                   ${blue}
        set-face global ts_comment                     ${overlay0}+i
        set-face global ts_conceal                     ${mauve}+i
        set-face global ts_constant                    ${peach}
        set-face global ts_constant_builtin_boolean    ${sky}
        set-face global ts_constant_character          ${yellow}
        set-face global ts_constant_macro              ${mauve}
        set-face global ts_constructor                 ${sapphire}
        set-face global ts_diff_plus                   ${green}
        set-face global ts_diff_minus                  ${red}
        set-face global ts_diff_delta                  ${blue}
        set-face global ts_diff_delta_moved            ${mauve}
        set-face global ts_error                       ${red}+b
        set-face global ts_function                    ${blue}
        set-face global ts_function_builtin            ${blue}+i
        set-face global ts_function_macro              ${mauve}
        set-face global ts_hint                        ${blue}+b
        set-face global ts_info                        ${green}+b
        set-face global ts_keyword                     ${mauve}
        set-face global ts_keyword_conditional         ${mauve}+i
        set-face global ts_keyword_control_conditional ${mauve}+i
        set-face global ts_keyword_control_directive   ${mauve}+i
        set-face global ts_keyword_control_import      ${mauve}+i
        set-face global ts_keyword_directive           ${mauve}+i
        set-face global ts_label                       ${sapphire}+i
        set-face global ts_markup_bold                 ${peach}+b
        set-face global ts_markup_heading              ${red}
        set-face global ts_markup_heading_1            ${red}
        set-face global ts_markup_heading_2            ${mauve}
        set-face global ts_markup_heading_3            ${green}
        set-face global ts_markup_heading_4            ${yellow}
        set-face global ts_markup_heading_5            ${pink}
        set-face global ts_markup_heading_6            ${sapphire}
        set-face global ts_markup_heading_marker       ${peach}+b
        set-face global ts_markup_italic               ${pink}+i
        set-face global ts_markup_list_checked         ${green}
        set-face global ts_markup_list_numbered        ${blue}+i
        set-face global ts_markup_list_unchecked       ${sapphire}
        set-face global ts_markup_list_unnumbered      ${mauve}
        set-face global ts_markup_link_label           ${blue}
        set-face global ts_markup_link_url             ${sapphire}+u
        set-face global ts_markup_link_uri             ${sapphire}+u
        set-face global ts_markup_link_text            ${blue}
        set-face global ts_markup_quote                ${subtext0}
        set-face global ts_markup_raw                  ${green}
        set-face global ts_markup_strikethrough        ${subtext0}+s
        set-face global ts_namespace                   ${blue}+i
        set-face global ts_operator                    ${sky}
        set-face global ts_property                    ${sky}
        set-face global ts_punctuation                 ${overlay1}
        set-face global ts_punctuation_special         ${sky}
        set-face global ts_special                     ${blue}
        set-face global ts_spell                       ${mauve}
        set-face global ts_string                      ${green}
        set-face global ts_string_regex                ${peach}
        set-face global ts_string_regexp               ${peach}
        set-face global ts_string_escape               ${mauve}
        set-face global ts_string_special              ${blue}
        set-face global ts_string_special_path         ${green}
        set-face global ts_string_special_symbol       ${mauve}
        set-face global ts_string_symbol               ${red}
        set-face global ts_tag                         ${mauve}
        set-face global ts_tag_error                   ${red}
        set-face global ts_text                        ${text}
        set-face global ts_text_title                  ${mauve}
        set-face global ts_type                        ${yellow}
        set-face global ts_type_enum_variant           ${flamingo}
        set-face global ts_variable                    ${text}
        set-face global ts_variable_builtin            ${red}
        set-face global ts_variable_other_member       ${sapphire}
        set-face global ts_variable_parameter          ${maroon}+i
        set-face global ts_warning                     ${peach}+b

        # --- local: statusline follows the mode ---
        hook global ModeChange '.*:normal' %{
            set-face global StatusLineInfo ${crust},${green}
            set-face global StatusLineMode ${crust},${lavender}
            set-face global StatusLine     ${lavender},${mantle}
        }
        hook global ModeChange '.*:insert' %{
            set-face global StatusLineInfo ${crust},${mauve}
            set-face global StatusLineMode ${crust},${peach}
            set-face global StatusLine     ${peach},${mantle}
        }
    "
}

# --- local: kak-rainbow-rs ---
# The plugin defaults to hardcoded RainbowBrackets hues and a mocha-mantle scope
# background, so the colors have to follow the flavor too. try keeps this file
# loadable when the plugin is absent.
try %{
    set-option global rainbow_colors            rgb:fab387 rgb:f9e2af rgb:a6e3a1 rgb:89dceb rgb:89b4fa rgb:cba6f7
    set-option global background_rainbow_colors rgb:3f343b rgb:3f3b41 rgb:323b3f rgb:2e3a4a rgb:2e344c rgb:38324c
    set-option global rainbow_cursor_scope_color rgb:181825
}
