# `sops edit` on a new secret hands kak an empty /tmp/<digits>/<name>; the
# default finaleol=present would bake a "\n" into single-line tokens.
# Existing secrets keep the finaleol kak detected on load.
hook global BufOpenFile /tmp/\d+/[^/]+ %{
  evaluate-commands %sh{
    [ -s "$kak_buffile" ] || echo 'set-option buffer finaleol missing'
  }
}
