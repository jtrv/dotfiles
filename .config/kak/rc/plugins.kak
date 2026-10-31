bundle active-window.kak https://github.com/greenfork/active-window.kak %{
  set-face global InactiveCursor default,rgba:5d5d5dFF
}

bundle auto-pairs.kak https://github.com/alexherbo2/auto-pairs.kak %{ enable-auto-pairs }

bundle colorcol-rs https://github.com/jtrv/colorcol-rs
bundle-install-hook colorcol-rs %{ cargo install --locked --path . ; cargo clean }

bundle grug https://github.com/jtrv/grug
bundle-install-hook grug %{ cargo install --locked --path . ; cargo clean }

bundle indent.kak https://github.com/kirusfg/indent.kak %{
  set-indent global 2 false
  enable-detect-indent
  enable-auto-indent
}

bundle kak-ansi-rs https://github.com/jtrv/kak-ansi-rs
bundle-install-hook kak-ansi-rs %{ cargo install --locked --path . ; cargo clean }

bundle popup.kak https://github.com/enricozb/popup.kak
bundle-install-hook popup.kak %{ cargo install --locked --path . ; cargo clean }

bundle-noload kak-tree-sitter https://git.sr.ht/~hadronized/kak-tree-sitter
bundle-install-hook kak-tree-sitter %{ cargo install kak-tree-sitter ktsctl ; cargo clean }

bundle kakoune-auto-percent https://github.com/delapouite/kakoune-auto-percent

bundle kakoune-boost https://github.com/krobelus/kakoune-boost

bundle kakoune-cd https://github.com/delapouite/kakoune-cd %{
  alias global cdb change-directory-current-buffer
  alias global cdr change-directory-project-root
  alias global ecd edit-current-buffer-directory
  alias global pwd print-working-directory
}

bundle-noload kakoune-lsp https://github.com/kakoune-lsp/kakoune-lsp
bundle-install-hook kakoune-lsp %{ cargo binstall -y kak-lsp ; cargo clean }

bundle kakoune-state-save https://gitlab.com/Screwtapello/kakoune-state-save.git %{
  hook global KakBegin .* %{
    state-save-reg-load colon
    state-save-reg-load pipe
    state-save-reg-load slash
  }
  hook global KakEnd .* %{
    state-save-reg-save colon
    state-save-reg-save pipe
    state-save-reg-save slash
  }
}

bundle kakoune-text-objects https://github.com/Delapouite/kakoune-text-objects

bundle kakship https://github.com/eburghar/kakship %{
  require-module kakship
  kakship-enable
}
bundle-install-hook kakship %{ cargo install --locked --path . ; cargo clean }

bundle-noload skyspell https://github.com/your-tools/skyspell
bundle-install-hook skyspell %{ cargo binstall -y skyspell_kak --git https://github.com/your-tools/skyspell ; cargo clean }

# skyspell's add-* only act on *spelling* list lines ("<file>: <range> <word>"),
# so fake one for the word under the cursor; drop its jump to the list
define-command -params 1 skyspell-add -docstring 'skyspell-add <global|file|project|extension|lang>: ignore the word under the cursor' %{
  execute-keys <a-i>w
  evaluate-commands %sh{
    : "$kak_opt_skyspell_project"
    kak_selection="$kak_buffile: $kak_selection_desc $kak_selection" \
      skyspell-kak --lang "$kak_opt_skyspell_lang" "add-$1" | grep -vx skyspell-list
  }
}

bundle sudo-write.kak https://github.com/jtrv/sudo-write.kak %{
  set-option global fprint_mode true
  alias global sw 'sudo-write'
  alias global swq 'sudo-write-quit'
}

# navigate buffers
bundle kakoune-buffers https://github.com/delapouite/kakoune-buffers %{
  hook global WinDisplay .* info-buffers
    map global normal b -docstring 'buffers' %{:enter-buffers-mode <ret>}
    unmap global buffers o
    unmap global buffers D
    alias global bd  delete-buffer
    alias global bd! delete-buffer!
    alias global bf  buffer-first
    alias global bl  buffer-last
    alias global bo  buffer-only
    alias global bo! buffer-only-force
}

bundle caser https://github.com/jtrv/caser %{ require-module caser-recommended-bindings }
bundle-install-hook caser %{ cargo install --locked --path . ; cargo clean }

bundle kakoune-focus https://github.com/caksoylar/kakoune-focus

# edit/extend/trim selections one by one
bundle kakoune-phantom-selection https://github.com/occivink/kakoune-phantom-selection

# select/edit surrounding chars and tags
bundle Encapsul8 https://github.com/ElectricR/Encapsul8 %{
  set-option global encapsul8_mapping_action_surround_around_shortcut 's'
  set-option global encapsul8_mapping_action_surround_within_shortcut 'x'

  set-option global encapsul8_mapping_action_delete         'D'
  set-option global encapsul8_mapping_action_select_inner   'i'
  set-option global encapsul8_mapping_action_select_outer   'a'
  set-option global encapsul8_mapping_cancel                '<esc>'
  set-option global encapsul8_mapping_surround_shortcut     's'

  set-option global encapsul8_mapping_alias_angle_brackets  'n'
  set-option global encapsul8_mapping_alias_braces          'c'
  set-option global encapsul8_mapping_alias_double_quote    'd'
  set-option global encapsul8_mapping_alias_grave           'g'
  set-option global encapsul8_mapping_alias_parentheses     'p'
  set-option global encapsul8_mapping_alias_single_quote    'q'
  set-option global encapsul8_mapping_alias_square_brackets 'b'

  set-option global encapsul8_show_key_tips true
  require-module encapsul8-load-defaults-global
}
