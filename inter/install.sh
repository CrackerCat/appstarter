_adb_=$1
r=`$_adb_ shell wm size | cut -d ' ' -f 3`
wh=(${r//x/ })
echo "count=100
speed=1.0
start data >>

DispatchPointer(10000, 10000, 0, "$[${wh[0]}/4], `expr ${wh[1]} - 150`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(10000, 10000, 1, "$[${wh[0]}/4], `expr ${wh[1]} - 150`", 0, 0, 0, 0, 0, 0, 0)
UserWait(7000)"> inter/install.mks
$_adb_ push inter/install.mks /sdcard/ 

while  :
do
    $_adb_ shell "su -c 'monkey -f /sdcard/install.mks 1000'" 
done