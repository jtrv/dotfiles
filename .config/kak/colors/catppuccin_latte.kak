# Catppuccin Latte
#
# Base: https://github.com/catppuccin/kakoune (whiskers-generated, verbatim).
# Local additions, each marked below: LSP faces, tree-sitter faces, the
# mode-change statusline hooks, WhitespaceIndent, and kak-rainbow-rs colors.
# Keep the latte file in step -- it is this file with the palette swapped and
# its deviations marked.

evaluate-commands %sh{
    rosewater='rgb:dc8a78'
    flamingo='rgb:dd7878'
    pink='rgb:ea76cb'
    mauve='rgb:8839ef'
    red='rgb:d20f39'
    maroon='rgb:e64553'
    peach='rgb:fe640b'
    yellow='rgb:df8e1d'
    green='rgb:40a02b'
    teal='rgb:179299'
    sky='rgb:04a5e5'
    sapphire='rgb:209fb5'
    blue='rgb:1e66f5'
    lavender='rgb:7287fd'
    text='rgb:4c4f69'
    subtext1='rgb:5c5f77'
    subtext0='rgb:6c6f85'
    overlay2='rgb:7c7f93'
    overlay1='rgb:8c8fa1'
    overlay0='rgb:9ca0b0'
    surface2='rgb:acb0be'
    surface1='rgb:bcc0cc'
    surface0='rgb:ccd0da'
    base='rgb:eff1f5'
    mantle='rgb:e6e9ef'
    crust='rgb:dce0e8'

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
        # latte deviation: upstream's cursor foregrounds assume a dark flavor.
        # crust and surface2 are light here, so the pure swap left the main
        # cursor at 2.00 contrast and both Eol cursors below 1.5.
        set-face global PrimaryCursor      ${text},${rosewater}
        set-face global SecondaryCursor    ${text},${overlay0}
        set-face global PrimaryCursorEol   ${base},${lavender}
        set-face global SecondaryCursorEol ${base},${overlay1}
        set-face global LineNumbers        ${overlay1},${base}
        set-face global LineNumberCursor   ${rosewater},${surface2}+b
        set-face global LineNumbersWrapped ${rosewater},${surface2}+i
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
        # latte deviation: mocha uses peach for insert, but latte's peach is a
        # saturated orange rather than a light tint -- 2.45 against the
        # statusline text, where red gives 4.80. Foregrounds are base, not
        # crust, for the same reason (4.80 against 4.10 on red).
        hook global ModeChange '.*:normal' %{
            set-face global StatusLineInfo ${base},${green}
            set-face global StatusLineMode ${base},${lavender}
            set-face global StatusLine     ${lavender},${mantle}
        }
        hook global ModeChange '.*:insert' %{
            set-face global StatusLineInfo ${base},${mauve}
            set-face global StatusLineMode ${base},${red}
            set-face global StatusLine     ${red},${mantle}
        }
    "
}

# --- local: kak-rainbow-rs ---
# The plugin defaults to hardcoded RainbowBrackets hues and a mocha-mantle scope
# background, so the colors have to follow the flavor too. try keeps this file
# loadable when the plugin is absent.
try %{
    set-option global rainbow_colors            rgb:fe640b rgb:df8e1d rgb:40a02b rgb:04a5e5 rgb:1e66f5 rgb:8839ef
    set-option global background_rainbow_colors rgb:f1e0d9 rgb:ede5db rgb:dae7dc rgb:d2e8f3 rgb:d6e0f5 rgb:e2dbf4
    set-option global rainbow_cursor_scope_color rgb:e6e9ef
}
