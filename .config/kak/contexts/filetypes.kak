# filetypes Kakoune does not detect, so their kak-tree-sitter grammars would never load
hook global BufCreate .*\.([ct]sv|psv) %{ set-option buffer filetype %val{hook_param_capture_1} }
hook global BufCreate .*\.env %{ set-option buffer filetype env }
hook global BufCreate .*/(\.gitattributes|git/attributes) %{ set-option buffer filetype git-attributes }
hook global BufCreate .*/(\.gitconfig|\.git/config|git/config) %{ set-option buffer filetype git-config }
hook global BufCreate .*/go\.mod %{ set-option buffer filetype go-mod }
hook global BufCreate .*\.grep %{ set-option buffer filetype grep }
hook global BufCreate .*\.prisma %{ set-option buffer filetype prisma }
hook global BufCreate .*/requirements[^/]*\.txt %{ set-option buffer filetype requirements }
hook global BufCreate .*\.svelte %{ set-option buffer filetype svelte }
hook global BufCreate .*\.typ %{ set-option buffer filetype typst }
