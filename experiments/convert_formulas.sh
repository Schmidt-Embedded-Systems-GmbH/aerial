cat $1 | sed -e 's/U\[/UNTIL \[/g' -e 's/S\[/SINCE \[/g' -e 's/●\[/PREVIOUS \[/g' -e 's/○\[/NEXT \[/g' -e 's/∨/OR/g' -e 's/∧/AND/g' -e 's/¬/NOT /g' -e 's/p/p ()/g' -e 's/q/q ()/g' -e 's/r/r ()/g'
