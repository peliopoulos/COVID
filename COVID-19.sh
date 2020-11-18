#!/bin/bash

#prepare git
cd /home/peter/Documents/COVID-19/git
rm -rf COVID
git clone https://github.com/peliopoulos/COVID


#get Worldwide Case Counts
curl -o /home/peter/Documents/COVID-19/World-Case-Data.csv https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv
#get BC Case Counts
curl -o /home/peter/Documents/COVID-19/BC-Case-Data.csv http://www.bccdc.ca/Health-Info-Site/Documents/BCCDC_COVID19_Dashboard_Case_Details.csv
#get Ontario Case Counts
curl -o /home/peter/Documents/COVID-19/ON-Case-Data.csv https://data.ontario.ca/dataset/f4112442-bdc8-45d2-be3c-12efae72fb27/resource/455fd63b-603d-4608-8216-7d8647f43350/download/conposcovidloc.csv

#filter out Canada data from World
head -n 1 /home/peter/Documents/COVID-19/World-Case-Data.csv > /home/peter/Documents/COVID-19/Canada-Case-Data-DRAFT.csv
awk -F, '$2 ~ /^Canada$/ {print}' /home/peter/Documents/COVID-19/World-Case-Data.csv >> /home/peter/Documents/COVID-19/Canada-Case-Data-DRAFT.csv
#transpose Canada data
csvtool transpose /home/peter/Documents/COVID-19/Canada-Case-Data-DRAFT.csv > /home/peter/Documents/COVID-19/Canada-Case-Data-transposed.csv
#remove cruise ships
cut -d, -f4,5 --complement /home/peter/Documents/COVID-19/Canada-Case-Data-transposed.csv > /home/peter/Documents/COVID-19/git/COVID/Canada-Case-Data.csv
#remove extra lines
sed -i '2d;3d;4d' /home/peter/Documents/COVID-19/git/COVID/Canada-Case-Data.csv
#clean up wording
sed -i 's/Province\/State/Date/g' /home/peter/Documents/COVID-19/git/COVID/Canada-Case-Data.csv


#shorten names in Ontario data
sed -i 's/\"Region of Waterloo\, Public Health\"/Waterloo/g' /home/peter/Documents/COVID-19/ON-Case-Data.csv
sed -i 's/Halton Region Health Department/Halton/g' /home/peter/Documents/COVID-19/ON-Case-Data.csv
sed -i 's/Toronto Public Health/Toronto/g' /home/peter/Documents/COVID-19/ON-Case-Data.csv
sed -i 's/Middlesex-London Health Unit/London/g' /home/peter/Documents/COVID-19/ON-Case-Data.csv


#filter out the wanted regions from Ontario data and remove extra columns
awk -F, '$11 ~ /^Halton$/ {print}' /home/peter/Documents/COVID-19/ON-Case-Data.csv  > /home/peter/Documents/COVID-19/ON-Case-Data-filtered.csv
awk -F, '$13 ~ /^Waterloo$/ {print}' /home/peter/Documents/COVID-19/ON-Case-Data.csv  >> /home/peter/Documents/COVID-19/ON-Case-Data-filtered.csv 

awk -F, '$11 ~ /^Toronto$/ {print}' /home/peter/Documents/COVID-19/ON-Case-Data.csv  >> /home/peter/Documents/COVID-19/ON-Case-Data-filtered.csv 
awk -F, '$11 ~ /^London$/ {print}' /home/peter/Documents/COVID-19/ON-Case-Data.csv  >> /home/peter/Documents/COVID-19/ON-Case-Data-filtered.csv 
cut -d, -f2,11 /home/peter/Documents/COVID-19/ON-Case-Data-filtered.csv > /home/peter/Documents/COVID-19/ON-Case-Data-filtered-slim.csv





#remove extra columns from BC data
cut -d, -f1,2 /home/peter/Documents/COVID-19/BC-Case-Data.csv > /home/peter/Documents/COVID-19/BC-Case-Data-slim.csv

#shorten names in BC
sed -i 's/Fraser/LowerMainland/g' /home/peter/Documents/COVID-19/BC-Case-Data-slim.csv
sed -i 's/Vancouver Coastal/LowerMainland/g' /home/peter/Documents/COVID-19/BC-Case-Data-slim.csv
sed -i 's/Vancouver Island/Island/g' /home/peter/Documents/COVID-19/BC-Case-Data-slim.csv
sed -i 's/Out of Canada/Other/g' /home/peter/Documents/COVID-19/BC-Case-Data-slim.csv
sed -i 's/\"//g' /home/peter/Documents/COVID-19/BC-Case-Data-slim.csv
#remove header
sed -i '1d' /home/peter/Documents/COVID-19/BC-Case-Data-slim.csv




#combine Ontario and BC data

cat /home/peter/Documents/COVID-19/BC-Case-Data-slim.csv /home/peter/Documents/COVID-19/ON-Case-Data-filtered-slim.csv > /home/peter/Documents/COVID-19/Regional-Case-Draft.csv

#count unique lines
sort /home/peter/Documents/COVID-19/Regional-Case-Draft.csv | uniq -c > /home/peter/Documents/COVID-19/Regional-Case-Counts.csv
#remove leading whitespace
awk '{$1=$1;print}' /home/peter/Documents/COVID-19/Regional-Case-Counts.csv > /home/peter/Documents/COVID-19/Regional-Case-Counts-trimmed.csv
#replace first space with a comma
sed -r 's/\s+/,/' /home/peter/Documents/COVID-19/Regional-Case-Counts-trimmed.csv > /home/peter/Documents/COVID-19/Regional-Case-Counts-trimmed-csv.csv

#put header on regional file
echo "Date,Region,Case_Count" > /home/peter/Documents/COVID-19/git/COVID/Regional-Case-Data.csv

#put first column at the end
awk -F, '{ print $2,$3,$1}' OFS=, /home/peter/Documents/COVID-19/Regional-Case-Counts-trimmed-csv.csv >> /home/peter/Documents/COVID-19/git/COVID/Regional-Case-Data.csv


#upload files to git
cd COVID
cp /home/peter/Documents/COVID-19.sh .
git add Canada-Case-Data.csv Regional-Case-Data.csv COVID-19.sh
git commit -m "update files"
git push https://peliopoulos:K5matQ38LS8n8AC@github.com/peliopoulos/COVID --all --force

