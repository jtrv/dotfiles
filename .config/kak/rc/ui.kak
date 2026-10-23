# zdiff3 conflict-marker highlighting; toggled from the ui mode below
add-highlighter shared/zdiff3 group
add-highlighter shared/zdiff3/HEAD   regex ^<{7}\s.*?$  0:rgb:ff0000,rgb:000000
add-highlighter shared/zdiff3/PARENT regex ^\|{7}\s.*?$ 0:rgb:fff000,rgb:000000
add-highlighter shared/zdiff3/MERGED regex ^={7}$       0:rgb:fff000,rgb:000000
add-highlighter shared/zdiff3/CLOSE  regex ^>{7}\s.*?$  0:rgb:00ff00,rgb:000000
add-highlighter shared/zdiff3/diff regions
add-highlighter shared/zdiff3/diff/bg region ^<{7}\s ^>{7}\s fill default,rgb:000000

define-command ui-zdiff3-enable %{ add-highlighter window/zdiff3 ref zdiff3 }
define-command ui-zdiff3-disable %{ remove-highlighter window/zdiff3 }
define-command ui-zdiff3-toggle %{ try ui-zdiff3-enable catch ui-zdiff3-disable }

provide-module "ui" %{
  bundle ui.kak https://github.com/kkga/ui.kak %{
    set-option global ui_wrap_flags -width 100 -word -indent
    set-face global TrailingSpace default,red
    set-face global TodoComment "%opt{crust}ff,%opt{yellow}ff+bF"

    require-module "number_toggle_kak"
    define-command -override ui-line-numbers-toggle -docstring 'toggle line numbers' %{ number-toggle-toggle }
    define-command -override ui-line-numbers-enable -docstring 'enable line numbers' %{ number-toggle-enable }
    define-command -override ui-line-numbers-disable -docstring 'disable line numbers' %{ number-toggle-disable }

    define-command ui-blame-toggle %{ git blame }
    map global ui b -docstring 'toggle blame'   %{: ui-blame-toggle <ret>}

    define-command ui-indent-enable %{ add-highlighter window/indent show-whitespaces -lf '' -tab '' -spc ' ' -indent '▏' }
    define-command ui-indent-disable %{ remove-highlighter window/indent }
    define-command ui-indent-toggle %{ try ui-indent-enable catch ui-indent-disable }
    map global ui i -docstring 'toggle indent'   %{:ui-indent-toggle <ret>}

    define-command -override ui-lsp-enable %{
      echo -debug "Enabling LSP for filetype %opt{filetype}"
      lsp-enable-window
      lsp-auto-hover-enable
      lsp-auto-hover-insert-mode-enable
      lsp-inlay-diagnostics-enable window
      lsp-inlay-hints-enable window
      set-option window lsp_auto_highlight_references true
    }
    define-command ui-lsp-disable -override %{
      echo -debug "Disabling LSP for filetype %opt{filetype}"
      set-option window lsp_auto_highlight_references false
      lsp-auto-hover-disable
      lsp-auto-hover-insert-mode-disable
      lsp-inlay-diagnostics-disable window
      lsp-inlay-hints-disable window
      lsp-disable-window
    }
    define-command ui-lsp-toggle -override %{
      try ui-lsp-enable catch ui-lsp-disable
      trigger-user-hook ui-hl-changed
    }
    map global ui k -docstring 'toggle kak-lsp'   %{:ui-lsp-toggle <ret>}

    require-module "kak_rainbower"
    declare-option -hidden bool rainbow_enabled false
    define-command ui-rainbow-enable %{
      evaluate-commands %sh{ $kak_opt_rainbow_enabled && echo "fail %{rainbow already enabled}" }
      rainbow-enable-window
      set-option buffer rainbow_enabled true
    }
    define-command ui-rainbow-disable %{
      rainbow-disable-window
      set-option buffer rainbow_enabled false
    }
    define-command ui-rainbow-toggle %{ try ui-rainbow-enable catch ui-rainbow-disable }
    map global ui R -docstring 'toggle rainbow'   %{:ui-rainbow-toggle <ret>}

    declare-option -hidden bool colorcol_enabled false
    define-command ui-colorcol-enable %{
      evaluate-commands %sh{ $kak_opt_colorcol_enabled && echo "fail %{colorcol already enabled}" }
      colorcol-enable; colorcol-refresh-continuous;
      set-option buffer colorcol_enabled true
    }
    define-command ui-colorcol-disable %{
      colorcol-disable
      set-option buffer colorcol_enabled false
    }
    define-command ui-colorcol-toggle %{ try ui-colorcol-enable catch ui-colorcol-disable }
    map global ui r -docstring 'toggle colorcol'   %{:ui-colorcol-toggle <ret>}

    map global ui z -docstring 'toggle zdiff3'   %{:ui-zdiff3-toggle <ret>}

    hook global WinCreate .* %{
      ui-line-numbers-enable
      ui-indent-enable
      ui-lint-enable
      ui-git-diff-enable
      ui-rainbow-enable
      ui-todos-enable
      ui-trailing-spaces-enable
      ui-zdiff3-enable
    }
  }
}
require-module "ui"
