#!/bin/bash
clear
response=$(curl -L -s -XPOST \
-H "content-type: application/json" \
-d '{
"token": "UEfuKfM4pN7M9mjPegS8r9Z3AMsq75",
"domain": "heise.de",
"date_format": "dd.MM.yyyy",
"from": "01.01.2025",
"to": "31.01.2025",
"result_count": 1000,
"conversion" : 2,
"object_type": ["article"],
"response_fields": ["title", "url", "publish_date", "loyalty", "recirculation", "word_count", "scroll_depth_avg", "time_spend_avg", "fast_exit", "conversion", "keywords"]
}' \
https://app.upscore.com/api/TopObjects)
echo -e "\033[0;33m"
echo "Total Views"
echo $response | jq '.[]' | jq -r '.total_views' | awk '{sum+=$0} END{print sum}' 

echo $response | jq  '[map(.url) | add ]' | sed 's/https/ https/g' > tmp_url
tmp_url=$(sed 1d tmp_url)
content_url=$(echo ${tmp_url:4})
echo ${content_url::-3} > urls.txt
sed -i 's/\s\+/\n/g' urls.txt
rm tmp_url

cat urls.txt | wc -l
echo "articles were found"
 
echo -e "URL;Title;Meta-Description" > metadata.tsv
echo -e "\033[00;0m"
echo "fetch content"

i=1
  while read -r url; do
  	echo -ne "$i \r"
    curl -s -k -L "$url" > tmp_file
    title=$(cat tmp_file | xmllint --html --xpath '/html/head/title/text()' - 2>/dev/null)
    metadesciption=$(cat tmp_file | xmllint --html --xpath 'string(/html/head/meta[@name="description"]/@content)' - 2>/dev/null)
    echo -e "\"$url\";\"${title:5}\";\"$metadesciption\"" >> metadata.tsv
    i=$((i+1))
  done < "urls.txt"

rm urls.txt 
rm tmp_file