function gen_completions
  set COMPLETIONS_DIR "$XDG_DATA_HOME"/fish/generated_completions

  # no stdout commands
  bun completions "$COMPLETIONS_DIR" &
  pueue completions fish "$COMPLETIONS_DIR" &

  # stdout commands
  echo "\
  atuin gen-completions --shell=fish
  clipcatctl completions fish
  clipcatd completions fish
  clipcat-menu completions fish
  dprint completions fish
  erd --completions=fish
  fd --gen-completions=fish
  glow completion fish
  just --completions=fish
  kondo --completions=fish
  onefetch --generate=fish
  procs --gen-completion-out=fish
  rg --generate=complete-fish
  sniffglue --gen-completions=fish
  trip --generate=fish
  watchexec --completions=fish \
  " | while read -l script
      set cmd (echo $script | cut -d ' ' -f 1)
      eval $script > "$COMPLETIONS_DIR/$cmd.fish" &
  end

  # https://github.com/rust-dc/fish-manpage-completions

  fish-manpage-completions \
    --manpath \
    --directory "$COMPLETIONS_DIR" \
    --progress &

  wait && echo "completions completely completed"
end
