hook global WinSetOption current_bufname=.*?\.prisma$ %{ set-option buffer filetype prisma }

hook global WinSetOption filetype=prisma %{
  ui-lsp-enable
}
