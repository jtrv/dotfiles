function config-grep -d "grep config files in kak"
  rg \
    --color=always \
    --smart-case \
    --with-filename \
    --line-number \
    --column \
    $argv \
    (config ls-files) |
    kak -e "set-option buffer filetype grep"
end
complete -c config-grep -w rg

function kk -d "make path and edit in kak"
  for i in $argv
    mkdir -p (dirname $i)
    k $i
  end
end
complete -c kk -F

function kd -d "edit all fd results in kak"
  k (rg -lI . | lscolors | sk --color=always --preview="_fzf_preview_file {}")
end

function kg -d "grep with kakoune"
  rg \
    --color=always \
    --smart-case \
    --with-filename \
    --line-number \
    --column \
    $argv |
    kak -e 'set-option buffer filetype grep'
end
complete -c kg -w rg

function kif -d "open delta output in kak"
  diff -u $argv | kak -e 'set-option buffer filetype diff'
end
complete -c kdf -w diff

function klg -d "kakoune live grep"
  kak -e 'live-grep; buffer-only;echo "live-grep"; info-buffers'
end
