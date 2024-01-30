hook window -group diff-hooks NormalKey <ret> diff-jump
hook -once -always window WinSetOption filetype=.* %{ remove-hooks window diff-hooks }
