

function print_mode {
#mode can be 0 -> aerial MTL naive,
#            1 -> aerial MTL local,
#            2 -> aerial MTL global,
#            3 -> aerial MDL naive,
#            4 -> aerial MDL local,
#            5 -> aerial MDL global,
#            6 -> monpoly,
#            7 -> montre
#            8 -> aerial MTL bdd default
#            9 -> aerial MTL bdd partial default
   if [ "$1" -eq "0" ]
   then
     echo "aerial_MTL_naive"
   elif [ "$1" -eq "1" ]
   then
     echo "aerial_MTL_local"
   elif [ "$1" -eq "2" ]
   then
     echo "aerial_MTL_global"
   elif [ "$1" -eq "3" ]
   then
     echo "aerial_MDL_naive"
   elif [ "$1" -eq "4" ]
   then
     echo "aerial_MDL_local"
   elif [ "$1" -eq "5" ]
   then
     echo "aerial_MDL_global"
   elif [ "$1" -eq "6" ]
   then
     echo "monpoly"
   elif [ "$1" -eq "7" ]
   then
     echo "montre"
   elif [ "$1" -eq "8" ]
   then
     echo "aerial_bdd_default"
   elif [ "$1" -eq "9" ]
   then
     echo "aerial_bdd_partial_default"  
   else
     echo "???"
   fi
}


function read_mode {

  while read  p || [[ -n "$p" ]]; do
  print_mode $p
  done < ./mods

}

function format_mode {
  local line=$(read_mode)
  echo $line | sed -E "s/ /, /g"
}

function run {
    #command to run
    local cmd="$1"
    #params to print
    local params="$2"

    #run the command, parse results...
    local ts=$(gdate +%s%N)
    local result=$(eval "$TIME $TIMEOUT $cmd")
    local time=$((($(gdate +%s%N) - $ts)/1000000)) 
    local space=$(echo $result | cut -d " " -f7)
    #local time=$(echo $result | cut -d " " -f1)

    # step 3 (see below)
    if [ "$time" -gt "100000" ]
    then
      local time="${time} (timeout)"
      echo "timeout" >> $tmpfile
    fi

    #print
    echo "$params, $space, $time"

}
