# Defined via `source`
function warehouse

    echo -e "--paru\n"                   > ~/.warehouse
        paru -Qetq | sd "^x[d-o].*\n" "" >> ~/.warehouse
        
    echo -e "\n\n\n--cargo\n"            >> ~/.warehouse
        cargo install --list |\
        sd "v\d.*\n" "\n" |\
        sd "^\s.*\n" ""                  >> ~/.warehouse
      
    echo -e "\n\n\n--fish-plugins\n" 	 >> ~/.warehouse
    /bin/cat ~/.config/fish/fish_plugins >> ~/.warehouse

    config diff ~/.warehouse # &&
    config add ~/.warehouse &&
    config commit -m "Warehousing packages"
end
