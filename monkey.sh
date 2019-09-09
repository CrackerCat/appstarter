#!/bin/bash

excludeApp="com.topjohnwu.magisk,com.android.settings"
excludeAppArr=${excludeApp//,/ }


packagesArr=()
getDevicePkg(){
    checkOnline
    packages=`$_adb_  shell 'pm list packages'`
    for p in $packages
    do
        #package:com.qualcomm.embms
        pa=(${p//:/ })
        packagesArr+=(${pa[1]})
    done
}

installTargetPkg(){
    getDevicePkg
    #echo "Start monkey(install.sh background)"
    bash inter/install.sh "$_adb_" &
    PID=$!
    disown $PID

    echo "=======install apps======="
    if [ ! -d "apps" ]; then
        mkdir apps
    fi

    for p in $targetAppArr
    do    
        if [[ " ${packagesArr[@]} " =~ " $p " ]]
        then
            echo "$p installed"
            continue
        fi

        if [ ! -f "apps/"$p".apk" ]
        then
            r=`python3 inter/packageinfo-get.py -p $p`
            if [ "$r" = "error" ]
            then
                echo "[!]$p name error"
            else
                echo "Downloading... $p"
                wget $r -O apps/$p".apk.tmp" &>/dev/null
                #防止下载过程被中断，apk无法解析
                mv apps/$p".apk.tmp" apps/$p".apk"
            fi
        fi
        if [ -f  "apps/$p.apk" ]
        then
            echo "Installing $p"
            $_adb_  install apps/$p".apk"  &>/dev/null
        else
            echo "[!]Install error $p"
        fi
        
    done
    echo "Install done"

    ps -ef | awk '/bash inter\/install.sh/ { system("kill -9 " $2) }' &>/dev/null
    pid=`$_adb_ shell 'ps -ef' | awk '/com\.android\.commands\.monkey/ { print $2 }'`
    $_adb_ shell su -c "kill -9 $pid" &>/dev/null
}

downloadTarget(){
    getDevicePkg
    if [ ! -d "apps" ]; then
        mkdir apps
    fi

    for p in $targetAppArr
    do    
        if [ ! -f "apps/"$p".apk" ]
        then
            if [[ " ${packagesArr[@]} " =~ " $p " ]]
            then
                r=`$_adb_ shell "pm path $p"`
                r1=(${r//:/ })
                if [ -n "${r1[1]}" ]
                then
                    echo "Pull $p.apk from device"
                    $_adb_ pull ${r1[1]} apps/$p".apk.tmp"
                    mv apps/$p".apk.tmp" apps/$p".apk"
                fi
            else
                r=`python3 inter/packageinfo-get.py -p $p`
                if [ "$r" = "error" ]
                then
                    echo "[!]$p name error"
                else
                    echo "Downloading... $p"
                    wget $r -O apps/$p".apk.tmp" #&>/dev/null
                    #防止下载过程被中断，apk无法解析
                    mv apps/$p".apk.tmp" apps/$p".apk"
                fi
            fi
        else
            echo "$p exists"
        fi
    done
    echo "Download done"
}

uninstallTargetApp(){
    for p in $targetAppArr
    do
        echo "Uninstalling "$p
        $_adb_ shell pm uninstall $p
    done
}

getpkglist(){
    if [ "$1" = "xiaomi" ]
    then
        #printf "Getting from pkglist-raw...\n"
        r=`python3 inter/packageinfo-get.py -f pkglist-raw`
        echo $r
        echo "See file pkglist-app.mi.com"
    else
        r=`python3 inter/packageinfo-get.py -p $1 -s`
        echo $r
    fi
}

#根据apk文件获取导出组件，然后依次启动
monkeyTest(){
    installTargetPkg

    #设置selinux
    #cmd: Failure calling service activity: Failed transaction
    $_adb_ shell "su -c 'setenforce 0'"

    echo '=======monkey start======='
    $_adb_ shell 'mkdir /sdcard/monkeylogs' &>/dev/null
    for p in $targetAppArr
    do
        if [[ " ${excludeAppArr[@]} " =~ " $p " ]]
        then
            continue
        fi

        echo "==$p=="
        checkOnline
        
        #apps目录下是否存在apk，否则从设备pull
        if [ ! -f "apps/"$p".apk" ]
        then
            r=`$_adb_ shell "pm path $p"`
            r1=(${r//:/ })
            if [ -z "${r1[1]}" ]
            then
                echo '[!]Error, device has no app '$p
                continue
            else
                echo "Pull $p.apk from device"
                $_adb_ pull ${r1[1]} apps/$p".apk.tmp"
                mv apps/$p".apk.tmp" apps/$p".apk"
            fi    
        fi

        r=`$_adb_ shell 'ps -ef' | grep frida-helper`
        if [ -z "$r" ]
        then
            echo '[!]frida server closed'
        else
            frida -D $_deviceid_ --no-pause -l inter/unload_ssl.js -f $p  &>/dev/null  &
            PID=$!
            disown $PID
            sleep 1
        fi
        
        #启动service
        r=`python3 inter/apkcookpy/apkcook.py -p "apps/"$p".apk" -m s 2>/dev/null`
        serviceArr=(${r//,/ })
        for s in "${serviceArr[@]}"
        do
            echo $s
            $_adb_ shell "su -c 'am start-service $p/$s'" &>/dev/null
            sleep 1
        done
        
        #申请权限+广告滑屏monkey，会判断当前运行APP是否本app
        # bash inter/init.sh  "$_adb_" $p &
        # PID=$!
        # disown $PID

        #echo "Get all exported activities"
        r=`python3 inter/apkcookpy/apkcook.py -p "apps/"$p".apk" -m a 2>/dev/null`
        activityArr=(${r//,/ })
        #解析错误或数量太少
        if [ "$r" =  "" ] || [ ${#activityArr[@]} -le 2 ]
        then
            echo "[!]Get exported activities error"
            $_adb_ shell "su -c 'monkey -p $p -vvv  --throttle 100 --pct-syskeys 0  --ignore-crashes  1333 > /sdcard/monkeylogs/$p.log'" &>/dev/null

        else
            for a in "${activityArr[@]}"
            do
                #防止ANR卡死，20s超时
                bash inter/timeout.sh "$_adb_" $p &
                echo $a
                
                $_adb_ shell "su -c 'am start -n $p/$a'" &>/dev/null
                sleep 1
                $_adb_ shell "su -c 'monkey -p $p -vvv  --throttle 100 --pct-syskeys 0  --ignore-crashes 133 > /sdcard/monkeylogs/$p.log'" &>/dev/null
            done
        fi

        ps -ef | awk '/bash inter\/init.sh/ { system("kill -9 " $2) }' &>/dev/null
        ps -ef | awk '/inter\/unload_ssl.js/ { system("kill -9 " $2) }' &>/dev/null
        pid=`$_adb_ shell 'ps -ef' | awk '/com\.android\.commands\.monkey/ { print $2 }'`
        $_adb_ shell su -c "kill -9 $pid" &>/dev/null
        $_adb_ shell am force-stop $p

    done
}
checkOnline(){
    if [ -z $_deviceid_ ]
    then
        #设备在线检查
        deviceids=(`adb devices -l | grep 'device '|awk '{print $1}' `)
        if [ ${#deviceids[@]} -gt 1 ]
        then
            echo "[!]Support only one device, there are more..."
            echo "[*]Please add -s device_id, select the device to run"
            adb devices
            exit
        elif [ ${#deviceids[@]} -eq 0 ]
        then
            echo "[!]No device available"
            exit
        fi
    else
        out=`$_adb_  shell id 2>/dev/null`
        if [ -z "$out" ]
        then
            echo "Device is offline, exiting..."
            exit
        fi
    fi
    
}

ctrl_c(){
    #清理安装过程的monkey
    echo "exiting..."
    ps -ef | awk '/bash inter\/install.sh/ { system("kill -9 " $2) }' &>/dev/null
    ps -ef | awk '/inter\/unload_ssl.js/ { system("kill -9 " $2) }' &>/dev/null
    ps -ef | awk '/bash inter\/init.sh/ { system("kill -9 " $2) }' &>/dev/null
    pid=`$_adb_  shell 'ps -ef' | awk '/com\.android\.commands\.monkey/ { print $2 }'`
    $_adb_  shell su -c "kill -9 $pid" &>/dev/null
    exit
}
trap ctrl_c INT

echoHelp(){
    echo "Usage: ./monkey.sh OPTION"
    echo "1, -m 文件或包名列表(逗号分割)  ->  monkey测试"
    echo "2, -i 文件或包名列表  ->  批量安装"
    echo "3, -u 文件或包名列表  ->  批量删除"
    echo "4, -l 包名或包名前缀  ->  搜索关联APP"
    echo "5, -x  ->  搜索xiaomi关联APP"
    echo "6, -c  ->  清理后台进程"
    echo "7, -s device_id  ->  指定运行设备(adb devices获取)"
    echo "退出: Ctrl+C"
}

_adb_="adb   "
_deviceid_=""

echo "[*]需要python3 with requests, beautifulsoup4"

while getopts "i:u:m:l:xcd:s:" arg
do
    case $arg in
    s)
        _adb_="adb -s "$OPTARG
        out=`$_adb_ shell id 2>/dev/null`
        if [ -z "$out" ]
        then
            echo "Device id error, exiting..."
            echo ""
            adb devices
            exit
        fi
        _deviceid_=$OPTARG
        
        ;;

    i)
        if [ -f "$OPTARG" ]
        then
            echo "File: "$OPTARG
            targetAppArr=`cat $OPTARG`
        else
            echo "Pkglist: "$OPTARG
            targetApp=$OPTARG
            targetAppArr=${targetApp//,/ }
        fi
        installTargetPkg
        ;;

    u)
        if [ -f "$OPTARG" ]
        then
            echo "File: "$OPTARG
            targetAppArr=`cat $OPTARG`
        else
            echo "Pkglist: "$OPTARG
            targetApp=$OPTARG
            targetAppArr=${targetApp//,/ }
        fi
        uninstallTargetApp
        ;;

    m)
        if [ -f "$OPTARG" ]
        then
            echo "File: "$OPTARG
            targetAppArr=`cat $OPTARG`
        else
            echo "Pkglist: "$OPTARG
            targetApp=$OPTARG
            targetAppArr=${targetApp//,/ }
        fi
        monkeyTest
        ;;

    c)
        echo "Clean background task"
        ctrl_c
        ;;

    l)
        r=`getpkglist $OPTARG`
        echo $r
        ;;

    x)
        r=`getpkglist xiaomi`
        echo $r
        ;;
    
    d)
        if [ -f "$OPTARG" ]
        then
            echo "File: "$OPTARG
            targetAppArr=`cat $OPTARG`
        else
            echo "Pkglist: "$OPTARG
            targetApp=$OPTARG
            targetAppArr=${targetApp//,/ }
        fi
        downloadTarget
        ;;
    
    *)
        echoHelp
        ;;

    esac
done
if (( $OPTIND == 1 )); then
    echoHelp
    exit
fi