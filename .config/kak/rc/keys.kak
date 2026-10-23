###################### INSERT KEYS ######################

map global insert <c-v> -docstring 'insert mode paste'   %{<esc>Pi}

###################### PROMPT KEYS ######################

map global prompt <c-n> <tab>   -docstring 'next completion'
map global prompt <c-p> <s-tab> -docstring 'previous completion'

map global prompt <c-/> -docstring 'insert buffer directory'     '%sh{ dirname "$kak_buffile" }<a-!>/'
map global prompt <c-?> -docstring 'insert git root directory'   '%sh{ git rev-parse --show-toplevel }<a-!>/'

###################### NORMAL KEYS ######################

# clear selections
map global normal <a-space> <a-,> -docstring 'clear current (or nth) selection'
map global normal <a-esc> <a-,>   -docstring 'clear current (or nth) selection'
map global normal <esc> ,         -docstring 'clear multi-selection and keep (nth)'

# use w as a more ergonomic 'previous word'
map global normal w b         -docstring 'select previous word'
map global normal W B         -docstring 'extend previous word'
map global normal <a-w> <a-b> -docstring 'select previous BIG-WORD'
map global normal <a-W> <a-B> -docstring 'extend previous BIG-WORD'

# swap [] <a-[]>
map global normal '[' '<a-[>'     -docstring 'select upto previous object end'
map global normal '<a-[>' '['     -docstring 'select to previous object end'

map global normal ']' '<a-]>'     -docstring 'select upto next object end'
map global normal '<a-]>' ']'     -docstring 'select to next object end'

# select whole lines
map global normal J -docstring 'select next line'       %{Jx}
map global normal K -docstring 'select previous line'   %{Kx}

# make x/X inner and outer object selection
map global normal x     -docstring 'select inner'   %{<a-i>}
map global normal X     -docstring 'select outer'   %{<a-a>}

# select all matches
map global normal <a-x> -docstring 'select all matches'   %{<a-*>%s<ret>)}

# select/add next match
map global normal v     -docstring 'select next match'      %{<a-*>n}
map global normal <a-v> -docstring 'deselect current sel'   %{<a-*><a-n>}
map global normal V     -docstring 'add next match'         %{<a-*>N}
map global normal <a-V> -docstring 'add previous match'     %{<a-*><a-N>}

# case insensitive regex by default
map global normal /     -docstring 'search'                      %{/(?i)}
map global normal <a-/> -docstring 'search backwards'            %{<a-/>(?i)}
map global normal ?     -docstring '(extend) search'             %{?(?i)}
map global normal <a-?> -docstring '(extend) search backwards'   %{<a-?>(?i)}

map global prompt <c-i> -docstring 'ignore case'      %{<c-a>(?i)<c-e>}
map global prompt <a-n> -docstring '!= newlines'      %{<c-a>(?S)<c-e>}
map global prompt <c-.> -docstring '+ look-ahead'     %{<c-a>(?=)<c-b>}
map global prompt <a-.> -docstring '- look-ahead'     %{<c-a>(?!)<c-b>}
map global prompt <c-,> -docstring '+ look-behind'    %{<c-a>(?<lt>=)<c-b>}
map global prompt <a-,> -docstring '- look-behind'    %{<c-a>(?<lt>!)<c-b>}

hook global NormalKey '[sS/?]|<a-[kK/?]>' %{
info -title 'assertions' '<c-i>:    ignore case  (?i)
<a-n>:  . != newlines  (?S)
<c-.>:  + look-ahead   (?=...)
<a-.>:  - look-ahead   (?!...)
<c-,>:  + look-behind  (?<=...)
<a-,>:  - look-behind  (?<!...)
'
}

# (Un)Comment Lines
map global normal <#> -docstring 'comment'   %{:comment <ret>}

# new windows
map global normal <c-n> -docstring 'new client'     %{:new <ret>}
map global normal <c-N> -docstring 'new terminal'   %{:terminal fish <ret>}
map global normal +     -docstring 'new popup'      %{:popup fish <ret>}

map global normal <c-p> -docstring 'file-picker'    %{:file-picker <ret>}
