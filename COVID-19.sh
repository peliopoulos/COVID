#!/bin/bash

#prepare git
cd $HOME/Documents/COVID-19/git
rm -rf COVID
git clone https://github.com/peliopoulos/COVID


#get Worldwide Case Counts
curl -o $HOME/Documents/COVID-19/World-Case-Data.csv https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv
#get BC Case Counts
curl -o $HOME/Documents/COVID-19/BC-Case-Data.csv http://www.bccdc.ca/Health-Info-Site/Documents/BCCDC_COVID19_Dashboard_Case_Details.csv
#get Ontario Case Counts
curl -o $HOME/Documents/COVID-19/ON-Case-Data.csv https://data.ontario.ca/dataset/f4112442-bdc8-45d2-be3c-12efae72fb27/resource/455fd63b-603d-4608-8216-7d8647f43350/download/conposcovidloc.csv
curl -o $HOME/Documents/COVID-19/BC-Regional-Case-Data.csv http://www.bccdc.ca/Health-Info-Site/Documents/BCCDC_COVID19_Regional_Summary_Data.csv

#filter out Canada data from World
head -n 1 $HOME/Documents/COVID-19/World-Case-Data.csv > $HOME/Documents/COVID-19/Canada-Case-Data-DRAFT.csv
awk -F, '$2 ~ /^Canada$/ {print}' $HOME/Documents/COVID-19/World-Case-Data.csv >> $HOME/Documents/COVID-19/Canada-Case-Data-DRAFT.csv
#transpose Canada data
csvtool transpose $HOME/Documents/COVID-19/Canada-Case-Data-DRAFT.csv > $HOME/Documents/COVID-19/Canada-Case-Data-transposed.csv
#remove cruise ships
cut -d, -f4,5 --complement $HOME/Documents/COVID-19/Canada-Case-Data-transposed.csv > $HOME/Documents/COVID-19/git/COVID/Canada-Case-Data.csv
#remove extra lines
sed -i '2d;3d;4d' $HOME/Documents/COVID-19/git/COVID/Canada-Case-Data.csv
#clean up wording
sed -i 's/Province\/State/Date/g' $HOME/Documents/COVID-19/git/COVID/Canada-Case-Data.csv


#shorten names in Ontario data
sed -i 's/\"Region of Waterloo\, Public Health\"/Waterloo/g' $HOME/Documents/COVID-19/ON-Case-Data.csv
sed -i 's/Halton Region Health Department/Halton/g' $HOME/Documents/COVID-19/ON-Case-Data.csv
sed -i 's/Toronto Public Health/Toronto/g' $HOME/Documents/COVID-19/ON-Case-Data.csv
sed -i 's/Middlesex-London Health Unit/London/g' $HOME/Documents/COVID-19/ON-Case-Data.csv


#filter out the wanted regions from Ontario data and remove extra columns
awk -F, '$12 ~ /^Halton$/ {print}' $HOME/Documents/COVID-19/ON-Case-Data.csv  > $HOME/Documents/COVID-19/ON-Case-Data-filtered.csv
awk -F, '$12 ~ /^Waterloo$/ {print}' $HOME/Documents/COVID-19/ON-Case-Data.csv  >> $HOME/Documents/COVID-19/ON-Case-Data-filtered.csv 

awk -F, '$12 ~ /^Toronto$/ {print}' $HOME/Documents/COVID-19/ON-Case-Data.csv  >> $HOME/Documents/COVID-19/ON-Case-Data-filtered.csv 
awk -F, '$12 ~ /^London$/ {print}' $HOME/Documents/COVID-19/ON-Case-Data.csv  >> $HOME/Documents/COVID-19/ON-Case-Data-filtered.csv 
cut -d, -f2,12 $HOME/Documents/COVID-19/ON-Case-Data-filtered.csv > $HOME/Documents/COVID-19/ON-Case-Data-filtered-slim-name.csv
#filter for dates starting with 202 to remove junk data
awk -F, '$1 ~ /^202/ {print}' $HOME/Documents/COVID-19/ON-Case-Data-filtered-slim-name.csv  >> $HOME/Documents/COVID-19/ON-Case-Data-filtered-slim.csv





#remove extra columns from BC data
cut -d, -f1,2 $HOME/Documents/COVID-19/BC-Case-Data.csv > $HOME/Documents/COVID-19/BC-Case-Data-slim.csv

#shorten names in BC
sed -i 's/Fraser/LowerMainland/g' $HOME/Documents/COVID-19/BC-Case-Data-slim.csv
sed -i 's/Vancouver Coastal/LowerMainland/g' $HOME/Documents/COVID-19/BC-Case-Data-slim.csv
sed -i 's/Vancouver Island/Island/g' $HOME/Documents/COVID-19/BC-Case-Data-slim.csv
sed -i 's/Out of Canada/Other/g' $HOME/Documents/COVID-19/BC-Case-Data-slim.csv
sed -i 's/\"//g' $HOME/Documents/COVID-19/BC-Case-Data-slim.csv
#remove header
sed -i '1d' $HOME/Documents/COVID-19/BC-Case-Data-slim.csv

#remove extra columms from BC Regional Data
cut -d, -f1,4,5 $HOME/Documents/COVID-19/BC-Regional-Case-Data.csv > $HOME/Documents/COVID-19/BC-Regional-Case-Data-slim.csv

#filter by Northern Interior cases
awk -F, '$2 ~ /^"Northern Interior"$/ {print}' $HOME/Documents/COVID-19/BC-Regional-Case-Data-slim.csv  > $HOME/Documents/COVID-19/BC-Regional-Case-Data-filtered.csv

#shorten names in BC Regional
sed -i 's/\"Northern Interior\"/PrinceGeorgeArea/g' $HOME/Documents/COVID-19/BC-Regional-Case-Data-filtered.csv


#combine Ontario, BC data
cat $HOME/Documents/COVID-19/BC-Case-Data-slim.csv $HOME/Documents/COVID-19/ON-Case-Data-filtered-slim.csv > $HOME/Documents/COVID-19/Regional-Case-Draft.csv

#count unique lines
sort $HOME/Documents/COVID-19/Regional-Case-Draft.csv | uniq -c > $HOME/Documents/COVID-19/Regional-Case-Counts.csv
#remove leading whitespace
awk '{$1=$1;print}' $HOME/Documents/COVID-19/Regional-Case-Counts.csv > $HOME/Documents/COVID-19/Regional-Case-Counts-trimmed.csv
#replace first space with a comma
sed -r 's/\s+/,/' $HOME/Documents/COVID-19/Regional-Case-Counts-trimmed.csv > $HOME/Documents/COVID-19/Regional-Case-Counts-trimmed-csv.csv

#put header on regional file
echo "Date,Region,Case_Count" > $HOME/Documents/COVID-19/git/COVID/Regional-Case-Data.csv

#add BC Regional Data
cat $HOME/Documents/COVID-19/BC-Regional-Case-Data-filtered.csv >> $HOME/Documents/COVID-19/git/COVID/Regional-Case-Data.csv

#put first column at the end
awk -F, '{ print $2,$3,$1}' OFS=, $HOME/Documents/COVID-19/Regional-Case-Counts-trimmed-csv.csv >> $HOME/Documents/COVID-19/git/COVID/Regional-Case-Data.csv



#create copy of this script without last line
sed \$d $HOME/Documents/COVID-19.sh > $HOME/Documents/COVID-19/git/COVID/COVID-19.sh
echo "#git push https://peliopoulos:[password]@github.com/peliopoulos/COVID --all --force" >> $HOME/Documents/COVID-19/git/COVID/COVID-19.sh

#copy files to GDrive
rclone copy /home/peter/Documents/COVID-19/git/COVID googledrive:"COVID Case Tracking"/RawData

#load the spreadsheet to allow it to update
curl "https://docs.google.com/spreadsheets/d/1XDWwxSS-zCiPFHNvUMkGefBX5MAwUWqnkIaYUUBMLNk/edit?usp=sharing" > /dev/null

#upload files to git
cd COVID

git add Canada-Case-Data.csv Regional-Case-Data.csv COVID-19.sh
git commit -m "update files"
#git push https://peliopoulos:[password]@github.com/peliopoulos/COVID --all --force
