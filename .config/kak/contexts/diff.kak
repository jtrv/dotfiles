hook global WinSetOption filetype=diff %{
    map global normal <ret> ': diff-jump<ret>'
}
