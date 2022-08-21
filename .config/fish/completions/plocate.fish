complete -c plocate -f -s "b" -l "basename" \
  -d "search only the file name portion of path names"

complete -c plocate -f -s "c" -l "count" \
  -d "print number of matches instead of the matches"

complete -c plocate -f -s "d" -l "database" \
  -d "(DBPATH) search for files in DBPATH"

complete -c plocate -f -s "i" \
  -d "search case-insensitively"

complete -c plocate -f -l "ignore-case" \
  -d "search case-insensitively"

complete -c plocate -f -s "l" -l "limit" \
  -d "(LIMIT) stop after LIMIT matches"

complete -c plocate -f -s "0" -l "null" \
  -d "delimit matches by NUL instead of newline"

complete -c plocate -f -s "N" -l "literal" \
  -d "do not quote filenames, even if printing to a tty"

complete -c plocate -f -s "r" -l "regex" -d "interpret patterns as extended regexps (slow)"

complete -c plocate -f -s "w" -l "wholename" \
  -d "search the entire path name (default; see -b)"

complete -c plocate -f -l "help" \
  -d "print this help"

complete -c plocate -f -l "version" \
  -d "print version information"
