#!/bin/bash
clear
timezone="Europe/Zurich"
script="${0##*/}"
rootdir=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
logfile="${script::-3}.log"
log="$rootdir/$logfile"
searchPattern="$rootdir/config/search_for.txt"
now=$(TZ=":$timezone" date)

DB_USER='root';
DB_PASSWD='password';
export MYSQL_PWD='password'

DB_NAME='competition_crawler';
TABLE='products';


######################### cleanup ######################
cd data
rm -rf *
cd ..
########################################################

# Uncomment 'mailto=' (remove #) to enable emailing the log upon completion
#mailto="ehlers@upscore.com"
mailsubj="$script log from $now"


logging() {
  now=$(TZ=":$timezone" date)
  if [[ -z "$1" || -z "$2" ]]; then
    echo "$now [ERROR] Nothing to log. Use:\nlogging <level> <result>"
    exit 2
  else
    echo "$now [$1] $2" >> $log
  fi
}

input="config/urls.txt"
#if [ -z "$1" ]; then
#  echo "$now [ERROR] Missing file input. Use:\n$rootdir/$script /path/to/urls.txt"
#  exit 2
#else
#  input="$1"
#fi


######################  crawling pages #########################
logging "INFO-1" "Reading file: $input"
echo -e "\033[0;33m"
echo "Crawling URL:"
echo -e "\033[01;0m"
cat $input|while read line; do
  printf "\r$line"
  logging "INFO-2" "Crawling URL: $line"
  datafile="data/${line:8}"
  logging "INFO-3" "creating file: ${datafile::-1}"
  
  curlstart=$(date +"%s")
  curlresult=$(curl -w "%{http_code} %{url_effective}" -sL -H "Accept:application/json" -o "${datafile::-1}" "${line::-1}")
  # curl parameters: -sS = silent; -L = follow redirects; -w = custom output format; -o = trash output
  logging "INFO-4" "$curlresult"
  curldone=$(date +"%s")
  difftime=$(($curldone-$curlstart))
  logging "INFO-5" "Crawl-time: $(($difftime / 3600)):$(($difftime / 60)):$(($difftime % 60))"
done
logging "INFO-6" "Done reading file: $input"



######################### search for pattern inside html ####################
cd data
cat $searchPattern|while read line; do
  echo -e "\033[0;33m"
  echo "${line::-1} Integrations:"
  echo -e "\033[00;1m"
  grep -Ril "${line::-1}" > hits.tmp
  cat hits.tmp

  cat hits.tmp|while read hit; do
    echo -e "\033[01;0m"
    #echo "insert into $TABLE (product_name,domain,datum) values ("${line::-1}" ,"${array[$key]}" ,"$now")"
    mysql --user=$DB_USER  --default_character_set utf8 $DB_NAME << EOF
insert into $TABLE (product_name,domain,datum) values ("${line::-1}" ,"$hit","$now");
EOF
  done
done
#sed -i 's/.\//https:\/\//g' ${rootdir}/*.csv
cd ..
echo -e "\033[01;0m"





####################################################################################


if [ ! -z "$mailto" -a "$mailto" != " " ]; then
  logging "INFO-7" "Sending Email to: $mailto"
  # Using postfix mail command to email the logfile contents
  cat $log | mail -s "$mailsubj" $mailto
fi
exit