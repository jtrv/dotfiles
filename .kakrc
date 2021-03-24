kak-lsp/kak-lsp" do %{
    cargo install --locked --force --path .
}
plug "andreyorst/powerline.kak" defer powerline %{
    #Configure powerline.kak as desired
    powerline-theme gruvbox
} config %{
    powerline-start
}
