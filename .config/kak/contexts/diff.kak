hook global WinSetOption filetype=diff %{
    hook buffer -group diff-hooks NormalKey <ret> diff-jump
    hook -once -always window WinSetOption filetype=.* %{ remove-hooks buffer diff-hooks }
}
