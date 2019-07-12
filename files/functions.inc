
function isUrl()
{
  regex="(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]"
  if [[ $1 =~ $regex ]]
  then
    echo 0
  else
    echo 1
  fi
}

function getGraphConfiguration()
{
  location=$1
  printf "location: $location\n"
  printf "neo4jConfig:\n    dump_configuration : true\n    dbms.pagecache.memory : 100G\n"
  printf "curies:\n"
  if [[ $(isUrl $2) == 0 ]]
  then
    curies=$(curl -s -L "$2" | sed 's/^/    /g')
    printf "$curies"
  else
    while IFS= read -r line
    do
      printf "    $line\n"
    done < $2
  fi
}
