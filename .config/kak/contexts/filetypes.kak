# filetypes Kakoune does not detect, so their kak-tree-sitter grammars would never load
hook global BufCreate .*\.([ct]sv|psv) %{ set-option buffer filetype %val{hook_param_capture_1} }
hook global BufCreate .*/(\.gitconfig|\.git/config|git/config) %{ set-option buffer filetype git-config }
hook global BufCreate .*/(\.gitattributes|git/attributes) %{ set-option buffer filetype git-attributes }
hook global BufCreate .*/go\.mod %{ set-option buffer filetype go-mod }
hook global BufCreate .*/requirements[^/]*\.txt %{ set-option buffer filetype requirements }
hook global BufCreate .*\.svelte %{ set-option buffer filetype svelte }
