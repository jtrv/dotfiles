if status is-interactive

abbr --add --global cp     'cp -i'
abbr --add --global mv     'mv -i'
abbr --add --global rm     'cnc'

abbr --add --global --set-cursor k- 'k ~/%'

abbr --add --global gitbit 'git commit --amend --no-edit --date="Sat 01 Jan 2022 16:20:00 PST"'
abbr --add --global --set-cursor ginit  "set CWD_NAME (basename '$PWD')
gh repo create --private '$CWD_NAME'
git init
git add .
git commit -e
git remote add origin 'https://github.com/jtravers-mxs%/$CWD_NAME.git'
git branch -M main
git push -u origin main"

end

