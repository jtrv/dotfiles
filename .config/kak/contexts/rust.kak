hook global WinSetOption filetype=rust %{
  # rustfmt on stdin can't see the crate's edition; a workspace member's
  # `edition.workspace = true` defers to an ancestor Cargo.toml, so keep walking up.
  evaluate-commands %sh{
    d=$(dirname "$kak_buffile") edition=
    while [ "$d" != / ] && [ "$d" != . ] && [ -z "$edition" ]; do
      [ -f "$d/Cargo.toml" ] && edition=$(sed -n 's/^edition *= *"\([0-9]*\)".*/\1/p' "$d/Cargo.toml" | head -n1)
      d=$(dirname "$d")
    done
    printf 'set-option window formatcmd %%{rustfmt --edition=%s}\n' "${edition:-2024}"
  }
  map window dev c -docstring "clippy"  ':cargo clippy --color=always<ret>'

  ui-lsp-enable
}
