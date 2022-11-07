
message="$1"
version="0"
./version_incrementer.exe "./pubspec.yaml" false
version=`cat version.txt`

# writing Changelog
changeLogFile='CHANGELOG.md'
allChangeLogFile='CHANGELOG-ALL.md'

touch TEMPCHANGELOG.md

version=`cat version.txt`
version=$(echo $version| tr -d '[:space:]')

echo "## $version" > TEMPCHANGELOG.md

echo "Please enter your changelog in the TEMPCHANGELOG.md file and then press enter"

code TEMPCHANGELOG.md

read confirm

fileContents=`cat TEMPCHANGELOG.md`

while [ "$fileContents" == "## $version" ]
do
    echo "Please enter your changelog in the TEMPCHANGELOG.md file and then press enter"
    read confirm
    fileContents=`cat TEMPCHANGELOG.md`
done

changeLogContents=`cat $allChangeLogFile`

echo -e "$fileContents\n$changeLogContents" > $allChangeLogFile
echo -e "$fileContents" > $changeLogFile

rm TEMPCHANGELOG.md

echo "====wrote CHANGELOG.md and CHANGELOG-ALL.md===="


git pull
echo "====Pulled===="

git add .
echo "====staged all git files===="




git commit -m "Updating to $version" -m "$message"
git push origin master

echo "====pushed as version $version===="
