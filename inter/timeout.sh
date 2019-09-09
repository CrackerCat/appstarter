_adb_=$1
for i in {30..1}
do
    sleep 1
done
$_adb_ shell am force-stop $2