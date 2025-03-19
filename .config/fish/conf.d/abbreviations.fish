if status is-interactive

abbr --add --global cp     'cp -i'
abbr --add --global mv     'mv -i'
abbr --add --global rm     'cnc'

abbr --add --global --set-cursor k- 'k ~/%'

abbr --add --global gitbit 'git commit --amend --no-edit --date="Sat 01 Jan 2022 16:20:00 PST"'
abbr --add --global --set-cursor ginit  '
set CWD_N (basename "$PWD"); set TRUNK_N "main";
gh repo create --private "$CWD_N";
git init; git add . ; git commit -e;
git remote add origin "https://github.com/%/$CWD_N.git";
git branch -M $TRUNK_N; git push -u origin $TRUNK_N';

abbr --add --global --set-cursor webpz 'magick % -resize 2500x2500 -quality 85 .webp'

end

