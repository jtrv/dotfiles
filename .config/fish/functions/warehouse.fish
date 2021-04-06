# Defined via `source`
function warehouse
    echo -e "--yay\n"    		> ~/.warehouse &&
    yay -Qetq               	>> ~/.warehouse &&
    echo -e "\n\n\n--cargo\n" 	>> ~/.warehouse &&
    cargo install --list    	>> .warehouse &&

    config add ~/.warehouse &&
    config commit -m "warehousing new packages"
end
