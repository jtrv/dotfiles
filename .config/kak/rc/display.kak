# rainbow delimiters + current scope
provide-module "kak_rainbower" %{
  bundle kak-rainbow-rs https://github.com/jtrv/kak-rainbow-rs
  bundle-install-hook kak-rainbow-rs %{ cargo install --locked --path . ; cargo clean }
}
# The colorscheme sets this plugin's colors, and set-option on an undeclared
# option fails -- so the module has to be loaded before the colorscheme, not
# lazily inside "ui". Without this the plugin's own defaults win, which are
# mocha-mantle and RainbowBrackets hues.
require-module "kak_rainbower"
# kak-tree-sitter adds its buffer highlighter asynchronously, after WinCreate
# enabled rainbow, so it lands later in the buffer group and repaints the
# brackets. Re-adding rainbow moves it back on top; the try skips buffers
# where rainbow is off.
define-command -override tree-sitter-user-after-highlighter %{
  try %{
    remove-highlighter buffer/rainbow
    add-highlighter buffer/rainbow ranges rainbow
  }
}

colorscheme catppuccin_mocha

# Faces for the nvim-treesitter capture names added in kak-tree-sitter's
# config.toml; kak-tree-sitter defaults them to `default` as they have no parent.
# After the colorscheme: kak-tree-sitter links e.g. ts_markup_list_unnumbered
# back to ts_markup_list, a face cycle until the colorscheme sets the child.
set-face global ts_boolean      ts_constant_builtin_boolean
set-face global ts_character    ts_constant_character
set-face global ts_conditional  ts_keyword_conditional
set-face global ts_escape       ts_constant_character_escape
set-face global ts_exception    ts_keyword_control_exception
set-face global ts_field        ts_variable_other_member
set-face global ts_float        ts_constant_numeric_float
set-face global ts_markup_link  ts_markup_link_text
set-face global ts_markup_list  ts_markup_list_unnumbered
set-face global ts_markup_strong ts_markup_bold
set-face global ts_method       ts_function_method
set-face global ts_module       ts_namespace
set-face global ts_number       ts_constant_numeric
set-face global ts_parameter    ts_variable_parameter
set-face global ts_repeat       ts_keyword_control_repeat
set-face global ts_storageclass ts_keyword_storage_modifier

set-option global ui_options terminal_assistant=none
set-option global scrolloff 1,3

# toggle relative line numbers with insert mode
provide-module "number_toggle_kak" %{
  bundle number-toggle.kak https://github.com/jtrv/number-toggle.kak %{
    require-module "number-toggle"
    set-option global number_toggle_params -hlcursor -cursor-separator '┼'
  }
}

set-option global git_diff_add_char "▍"
set-option global git_diff_mod_char "▍"
set-option global git_diff_del_char "━"
