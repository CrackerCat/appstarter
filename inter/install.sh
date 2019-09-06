r=`adb shell wm size | cut -d ' ' -f 3`
wh=(${r//x/ })
echo "count=100
speed=1.0
start data >>

DispatchPointer(10000, 10000, 0, "$[${wh[0]}/4], `expr ${wh[1]} - 150`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(10000, 10000, 1, "$[${wh[0]}/4], `expr ${wh[1]} - 150`", 0, 0, 0, 0, 0, 0, 0)
UserWait(7000)"> inter/install.mks
adb push inter/install.mks /sdcard/ &>/dev/null
while true :
do
    adb shell "su -c 'monkey -f /sdcard/install.mks 1000'" &>/dev/null
done