_adb_=$1
r=`$_adb_ shell wm size | cut -d ' ' -f 3`
wh=(${r//x/ })
#自动点击权限弹框：启动 - 点击右下三次
#自动点击权限弹框：启动 - 点击中右三次
#自动滑屏幕：右滑3次 - 点击下方中间
#count小于10存在问题
#LaunchActivity($1, $2)
echo "count=100
speed=1.0
start data >>

DispatchPointer(0, 0, 0, "$[${wh[0]}/4*3], `expr ${wh[1]} - 130`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "$[${wh[0]}/4*3], `expr ${wh[1]} - 130`", 0, 0, 0, 0, 0, 0, 0)
UserWait(1000)
DispatchPointer(0, 0, 0, "$[${wh[0]}/4*3], `expr ${wh[1]} - 130`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "$[${wh[0]}/4*3], `expr ${wh[1]} - 130`", 0, 0, 0, 0, 0, 0, 0)
UserWait(1000)
DispatchPointer(0, 0, 0, "$[${wh[0]}/4*3], `expr ${wh[1]} - 130`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "$[${wh[0]}/4*3], `expr ${wh[1]} - 130`", 0, 0, 0, 0, 0, 0, 0)
UserWait(500)
DispatchPointer(0, 0, 0, "`expr $[${wh[0]}/2] + 100`, `expr $[${wh[0]}/2] + 100`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "`expr $[${wh[0]}/2] + 100`, `expr $[${wh[0]}/2] + 100`", 0, 0, 0, 0, 0, 0, 0)
UserWait(500)
DispatchPointer(0, 0, 0, "`expr $[${wh[0]}/2] + 100`, `expr $[${wh[0]}/2] + 100`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "`expr $[${wh[0]}/2] + 100`, `expr $[${wh[0]}/2] + 100`", 0, 0, 0, 0, 0, 0, 0)
UserWait(500)
DispatchPointer(0, 0, 0, "`expr $[${wh[0]}/2] + 100`, `expr $[${wh[0]}/2] + 100`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "`expr $[${wh[0]}/2] + 100`, `expr $[${wh[0]}/2] + 100`", 0, 0, 0, 0, 0, 0, 0)

DispatchPointer(0, 0, 0, "`expr $[${wh[0]}/2] + 100`, $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 2, "$[${wh[0]}/2], $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "`expr $[${wh[0]}/2] - 100`, $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
UserWait(500)
DispatchPointer(0, 0, 0, "`expr $[${wh[0]}/2] + 100`, $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 2, "$[${wh[0]}/2], $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "`expr $[${wh[0]}/2] - 100`, $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
UserWait(500)
DispatchPointer(0, 0, 0, "`expr $[${wh[0]}/2] + 100`, $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 2, "$[${wh[0]}/2], $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "`expr $[${wh[0]}/2] - 100`, $[${wh[1]}/2]", 0, 0, 0, 0, 0, 0, 0)
UserWait(500)
DispatchPointer(0, 0, 0, "$[${wh[0]}/2], `expr ${wh[1]} - 150`", 0, 0, 0, 0, 0, 0, 0)
DispatchPointer(0, 0, 1, "$[${wh[0]}/2], `expr ${wh[1]} - 150`", 0, 0, 0, 0, 0, 0, 0)
UserWait(1000)

"> inter/init.mks
$_adb_ push inter/init.mks /sdcard/ &>/dev/null

while true :
do
    cur=`$_adb_  shell 'dumpsys window windows' | grep mCurrentFocus | cut -d'/' -f1 | rev | cut -d' ' -f1 | rev`
    if [ "$cur" == "$2" ]
    then
        $_adb_ shell "su -c 'monkey -f /sdcard/init.mks 1'" &>/dev/null
    fi
    sleep 1
    checkOnline
done