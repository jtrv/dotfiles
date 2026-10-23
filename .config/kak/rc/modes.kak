# Info boxes list keys in the order they were first mapped, and a plugin
# remapping a key keeps its slot. Sourced before the plugins so this order wins.

# free keys:
# b e h k n o p q r z , . '

map global user <space> : -docstring 'prompt'
map global user /       -docstring 'search'   %{<a-;>: global-picker <ret>}
map global user a       -docstring 'action'   %{:lsp-code-actions <ret>}
# remapped in place by caser-recommended-bindings
map global user c       -docstring 'case'     %{:enter-user-mode case<ret>}
map global user d       -docstring 'dev'      %{: enter-user-mode dev <ret>}
map global user f       -docstring 'focus'    %{:focus-toggle <ret>}
map global user g       -docstring 'grep'     %{:grep }
map global user i       -docstring 'docs'     %{:wud-find <ret>}
map global user j       -docstring 'jump'     %{: enter-user-mode jump <ret>}
map global user l       -docstring 'lsp'      %{: enter-user-mode lsp <ret>}
map global user m       -docstring 'math'     %{:math <ret>}
map global user P       -docstring 'phantom'  %{: enter-user-mode phantom <ret>}
map global user s       -docstring 'spell'    %{: enter-user-mode spell <ret>}
map global user S       -docstring 'seq'      %{:seq }
map global user t       -docstring 'tree'     %{: enter-user-mode tree-sitter <ret>}
map global user u       -docstring 'ui'       %{: enter-user-mode ui <ret>}
map global user v       -docstring 'view'     'v'
map global user w       -docstring 'write'    %{:write <ret>}
map global user x       -docstring 'xargs'    %{:xargs <ret>}
map global user y       -docstring 'yo'       %{:yo-buffer <ret>}

declare-user-mode dev
  map global dev c -docstring 'color'        %{:pastel <ret>}
  map global dev f -docstring 'format'       %{:format <ret>}
  map global dev F -docstring 'format sel'   %{:format-selections <ret>}
  map global dev n -docstring 'next lint'    %{:lint-next-message <ret>}
  map global dev p -docstring 'prev lint'    %{:lint-previous-message <ret>}
  map global dev l -docstring 'lint'         %{:lint <ret>}
  map global dev L -docstring 'lint-buffer'  %{:buffer *lint-output* <ret>}
  map global dev s -docstring 'set filetype' %{:set-filetype <ret>}

declare-user-mode jump
  map global jump c     -docstring 'next spell'            %{:skyspell-enable en_US ; skyspell-next <ret>}
  map global jump <a-c> -docstring 'prev spell'            %{:skyspell-enable en_US ; skyspell-previous <ret>}
  map global jump d     -docstring 'next diagnostic'       %{:lsp-diagnostics ; jump-next *diagnostics* <ret>}
  map global jump <a-d> -docstring 'prev diagnostic'       %{:lsp-diagnostics ; jump-previous *diagnostics* <ret>}
  map global jump f     -docstring 'next function'         %{:lsp-next-function <ret>}
  map global jump <a-f> -docstring 'prev function'         %{:lsp-previous-function <ret>}
  map global jump F     -docstring 'next function hover'   %{:lsp-next-hover-function <ret>}
  map global jump <a-F> -docstring 'prev function hover'   %{:lsp-previous-hover-function <ret>}
  map global jump g     -docstring 'next grep'             %{:jump-next *grep* <ret>}
  map global jump <a-g> -docstring 'prev grep'             %{:jump-previous *grep* <ret>}
  map global jump l     -docstring 'next lint'             %{:lint ; lint-next-message <ret>}
  map global jump <a-l> -docstring 'prev lint'             %{:lint ; lint-previous-message <ret>}
  map global jump m     -docstring 'next man'              %{:man-link-next <ret>}
  map global jump <a-m> -docstring 'prev man'              %{:man-link-prev <ret>}
  map global jump p     -docstring 'next phantom'          %{:phantom-selection-iterate-next <ret>}
  map global jump <a-p> -docstring 'prev phantom'          %{:phantom-selection-iterate-prev <ret>}
  map global jump s     -docstring 'next symbol'           %{:lsp-next-symbol <ret>}
  map global jump <a-s> -docstring 'prev symbol'           %{:lsp-previous-symbol <ret>}
  map global jump S     -docstring 'next sym hover'        %{:lsp-next-hover-symbol <ret>}
  map global jump <a-S> -docstring 'prev sym hover'        %{:lsp-previous-hover-symbol <ret>}
  map global jump t     -docstring 'next goto'             %{:jump-next *goto* <ret>}
  map global jump <a-t> -docstring 'prev goto'             %{:jump-previous *goto* <ret>}

# kak-lsp declares this mode; its own keys come first
map global lsp <minus> -docstring 'disable'   %{:lsp-disable-window <ret>}
map global lsp <plus>  -docstring 'enable'    %{:lsp-enable-window <ret>}

# edit/extend/trim selections one by one
declare-user-mode phantom
  map global phantom a -docstring 'add'        %{:phantom-selection-add-selection <ret>}
  map global phantom c -docstring 'clear'      %{:phantom-selection-select-all; phantom-selection-clear <ret>}
  map global phantom n -docstring 'next'       %{:phantom-selection-iterate-next <ret>}
  map global phantom p -docstring 'previous'   %{:phantom-selection-iterate-prev <ret>}

# spelling and grammar checking
declare-user-mode spell
  # enchant dict names, not nixpkgs attrs: hunspellDicts.en_US-large installs as en_US
  map global spell e -docstring 'english'    %{:skyspell-enable en_US <ret>}
  map global spell E -docstring 'español'    %{:skyspell-enable es_ANY <ret>}
  map global spell d -docstring 'disable'    %{:skyspell-disable <ret>}
  map global spell l -docstring 'list'       %{:skyspell-list <ret>}
  map global spell n -docstring 'next'       %{:skyspell-next <ret>}
  map global spell p -docstring 'previous'   %{:skyspell-previous <ret>}
  map global spell r -docstring 'replace'    %{:skyspell-replace <ret>}
