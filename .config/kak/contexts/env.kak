hook global WinSetOption current_bufname=\.env$ %{
  set-option buffer filetype env
  # ui-lsp-enable
}
