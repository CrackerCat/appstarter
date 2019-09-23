#coding: utf-8

import os, subprocess, sys
import threading, time
import logging, argparse
from inter.packageinfo_get import getpkg as packageinfo_get_getpkg
import urllib.request

logging.basicConfig(level = logging.INFO, format='%(asctime)s - %(levelname)s [%(filename)s:%(lineno)d]: %(message)s')
logging.getLogger("requests").setLevel(logging.WARNING)
logging.getLogger("urllib3").setLevel(logging.ERROR)


def execShellDaemon(cmd):
    return subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)

def execShell(cmd, t=120):
    ret = {}
    try:
        p = subprocess.run(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True, encoding='utf-8', timeout=t)
        if p.returncode == 0:
            ret['d'] = p.stdout
        else:
            ret['e'] = p.stderr
    except subprocess.TimeoutExpired:
        ret['e'] = 'timeout'

    return ret

def downloadFile(url, savepath):
    try:
        urllib.request.urlretrieve(url, savepath)
        return True
    except Exception as e:
        logging.info(str(e))
        return False

def downloadPkgList(adb, pkgList, devicePkg):
    logging.info('======Download======')

    curdir = os.path.dirname(os.path.abspath(__file__))
    for p in pkgList:
        logging.info('=='+p)
        sp = curdir+'/apps/'+p
        if os.path.isfile(sp+'.apk'):
            logging.info('exists')
            continue

        #从设备拉
        if p in devicePkg:
            cmd = adb + ' shell "pm path  '+p+'"'
            ret = execShell(cmd)
            if 'd' in ret.keys():
                path = ret.get('d').split(':')[1].strip()
                logging.info('Pull from device')
                cmd = adb + ' pull '+path+' '+sp
                ret = execShell(cmd)
                if 'd' in ret.keys():
                    execShell('mv '+sp+' '+sp+'.apk')
                else:
                    logging.info(ret.get('e'))
        else:
            #下载
            url = packageinfo_get_getpkg(p, False)
            if url :
                logging.info('Downloading ')
                if downloadFile(url, sp+'.tmp'):
                    ret = execShell('mv '+sp+'.tmp '+sp+'.apk')
                else:
                    logging.info('Downlod error ')
        
    logging.info('====Download done====')

def getinstallmks(adb):
    out = '''
    count=100
    speed=1.0
    start data >>

    DispatchPointer(10000, 10000, 0, xpoint, ypoint, 0, 0, 0, 0, 0, 0, 0)
    DispatchPointer(10000, 10000, 1, xpoint, ypoint, 0, 0, 0, 0, 0, 0, 0)
    UserWait(7000)
    '''
    ret = execShell(adb+' shell wm size')
    if 'e' in ret.keys():
        logging.info(ret.get('e'))
        return False
    #Physical size: 1080x1920
    tmp = ret.get('d')
    tmp = tmp.split(': ')
    tmp = tmp[1]
    tmp = tmp.split('x')
    width = int(tmp[0])
    height = int(tmp[1])
    out = out.replace('xpoint', str(int(width/4)))
    out = out.replace('ypoint', str(height - 150))
    
    ret = execShell(adb+' shell "echo \' '+out+'\' >/sdcard/install.mks"')
    if 'e' in ret.keys():
        logging.info(ret.get('e'))
        return False

    return True

def killPermissionRequest(adb, deviceid):
    #第一个app hook不到
    p = 'com.lbe.security.miui:ui'
    curdir = os.path.dirname(os.path.abspath(__file__))
    frida = ''
    cmd = adb + ' shell " getprop ro.product.model" '
    ret = execShell(cmd)
    model = ret.get('d').strip()
    tpcmd = adb + ' shell "ps -ef | grep '+p+'" '
    if model == 'MI MAX 2':
        tpcmd = adb + ' shell "ps  | grep '+p+'" '
        while True:
            ret = execShell(tpcmd)
            if 'd' in ret.keys():
                data = ret.get('d').split('\n')
                for d in data:
                    tmp = d.split()
                    if len(tmp) == 9 and tmp[8] == p:
                        logging.info('==Hook com.lbe.security.miui:ui  @mi5 pid:'+tmp[1])
                        if not frida:
                            if deviceid:
                                cmd = 'frida -D ' + deviceid+' '
                            else:
                                cmd = 'frida -U '
                                
                            cmd += ' --no-pause -l '+curdir+'/inter/kill_permission_request.js -p '+tmp[1]
                            frida = execShellDaemon(cmd)
                            
                        while not frida.poll():
                            time.sleep(10)
                        frida = ''
    else:
        while True:
            ret = execShell(tpcmd)
            if 'd' in ret.keys():
                data = ret.get('d').split('\n')
                for d in data:
                    tmp = d.split()
                    if len(tmp) == 8 and tmp[7] == p:
                        logging.info('==Hook com.lbe.security.miui:ui  @mi5 pid:'+tmp[1])
                        if not frida:
                            if deviceid:
                                cmd = 'frida -D ' + deviceid+' '
                            else:
                                cmd = 'frida -U '
                                
                            cmd += ' --no-pause -l '+curdir+'/inter/kill_permission_request.js -p '+tmp[1]
                            frida = execShellDaemon(cmd)
                            
                        while not frida.poll():
                            time.sleep(10)
                        frida = ''

def killMonkey(adb):
    logging.info('Clean monkey')
    cmd = adb + ' shell " getprop ro.product.model" '
    ret = execShell(cmd)
    model = ret.get('d')
    if model:
        model = model.strip()
    
    if model == 'MI MAX 2':
        cmd = adb + ' shell "ps  | grep com.android.commands.monkey" '
        ret = execShell(cmd)
        if 'd' in ret.keys():
            data = ret.get('d').split('\n')
            for d in data:
                tmp = d.split()
                if len(tmp) == 9 and tmp[8] == 'com.android.commands.monkey':
                    cmd = adb + ' shell "su -c \' kill -9 '+tmp[1]+'\' "'
                    ret = execShell(cmd)
                    if 'e' in ret.keys():
                        logging.info(ret.get('e'))
        logging.info('Clean monkey done')
        return
    
    cmd = adb + ' shell "ps -ef | grep com.android.commands.monkey" '
    ret = execShell(cmd)
    if 'd' in ret.keys():
        data = ret.get('d').split('\n')
        for d in data:
            tmp = d.split()
            if len(tmp) == 8 and tmp[7] == 'com.android.commands.monkey':
                cmd = adb + ' shell "su -c \' kill -9 '+tmp[1]+'\' "'
                ret = execShell(cmd)
                if 'e' in ret.keys():
                    logging.info(ret.get('e'))
    logging.info('Clean monkey done')

def startMonekyTest(adb, pkgList, devicePkg, deviceid):
    installPkg(adb, pkgList, devicePkg)
    from inter.apkcookpy.lib.apk import APKCook
    logging.info('=====start monkey=====')
    blacklist = [
        'com.android.settings',
        'com.topjohnwu.magisk'
    ]
    #设置selinux
    #cmd: Failure calling service activity: Failed transaction
    cmd = adb + ' shell "su -c \'setenforce 0\'" '
    ret = execShell(cmd)
    if 'e' in ret.keys():
        logging.info(ret.get('e'))
    
    cmd = adb + ' shell  "mkdir /sdcard/monkeylogs"'
    ret = execShell(cmd)
    
    curdir = os.path.dirname(os.path.abspath(__file__))
    frida = False
    cmd = adb + ' shell  "ps -ef | grep frida"'
    ret = execShell(cmd)
    if 'd' in ret.keys():
        if ret.get('d').find('frida-helper-') != -1:
            frida = True
        else:
            cmd = adb + ' shell  "ps | grep frida"'
            ret = execShell(cmd)
            if ret.get('d').find('frida-helper-') != -1:
                frida = True
    if not frida:
        logging.info('== frida server closed==')
        return

    #权限申请hook
    pt = threading.Thread(target=killPermissionRequest, args=(adb, deviceid), daemon=True)
    pt.start()
    
    for p in pkgList:
        if p in blacklist:
            continue
        #检查设备在线
        if not checkOnline(deviceid):
            logging.info('Device offline')
            return
        #准备apk文件
        sp = curdir+'/apps/'+p
        if not os.path.isfile(sp+'.apk'):
            cmd = adb + ' shell "pm path  '+p+'"'
            ret = execShell(cmd)
            if 'd' in ret.keys() and ret.get('d'):
                path = ret.get('d').split(':')[1].strip()
                logging.info('Pull from device')
                cmd = adb + ' pull '+path+' '+sp
                ret = execShell(cmd)
                if 'd' in ret.keys():
                    execShell('mv '+sp+' '+sp+'.apk')
                else:
                    logging.info(ret.get('e'))
        
        #解析activity/service组件
        if os.path.isfile(sp+'.apk'):
            logging.info('=='+p)
            
            #frida unload ssl
            if deviceid:
                cmd = 'frida -D '+deviceid+' '
            else:
                cmd = 'frida -U '
            cmd += ' --no-pause -l '+curdir+'/inter/unload_ssl.js -f '+p
            frida = execShellDaemon(cmd)

            encrypt = False
            try:
                activity = APKCook(sp+'.apk').show('a')
                if activity:
                    activity = activity.split(',')
                if len(activity) < 2:
                    encrypt = True

                #防止单个activity卡死
                timeout = 60
                timeoutThread = threading.Thread(target=timeoutKIll, args=(adb, p, timeout), daemon=True)
                timeoutThread.start()
                for a in activity:
                    logging.info(a)
                    cmd = adb + ' shell "su -c \'am start -n '+p+'/'+a+'\' " '
                    #timeout not working, because connected to pipe
                    execShell(cmd, 20)

                    cmd = adb + ' shell "su -c \'monkey -p '+p+' -vvv  --throttle 100 --pct-syskeys 0  --ignore-crashes 133 > /sdcard/monkeylogs/'+p+'.log\' " '
                    execShell(cmd, 20)
                    if not timeoutThread.is_alive():
                        timeoutThread = threading.Thread(target=timeoutKIll, args=(adb, p, timeout), daemon=True)
                        timeoutThread.start()

                service = APKCook(sp+'.apk').show('s')
                if service:
                    service = service.split(',')

                for s in service:
                    logging.info(s)
                    cmd = adb + ' shell "su -c \'am start-service  '+p+'/'+s+'\' " '
                    execShell(cmd, 20)
                    time.sleep(2)
                
            except Exception as e:
                # import traceback
                # traceback.print_exc()
                logging.info('==xml parse error'+str(e))
                encrypt = True
            
            if encrypt:
                cmd = adb + ' shell "su -c \'monkey -p '+p+' -vvv  --throttle 100 --pct-syskeys 0  --ignore-crashes 1333 > /sdcard/monkeylogs/'+p+'.log\' " '
                ret = execShell(cmd)
                # if 'e' in ret.keys():
                #     logging.info(ret.get('e'))

            cmd = adb + ' shell "am force-stop '+p+' " '
            ret = execShell(cmd)
            frida.terminate()
            time.sleep(0.2)
            # cmd = adb + ' shell \' su -c "am force-stop '+p+' "\' '
            # ret = execShell(cmd)

def installPkg(adb, pkgList, devicePkg):
    logging.info('======install======')

    #install monkey
    if not getinstallmks(adb):
        logging.info('Install mks error')
        sys.exit()
    installmcmd = adb + ' shell "su -c \' monkey -f /sdcard/install.mks 1000\'" '
    installm = execShellDaemon(installmcmd)
    ##

    curdir = os.path.dirname(os.path.abspath(__file__))
    for p in pkgList:
        logging.info('=='+p)
        if p in devicePkg:
            logging.info('exists')
            continue
        
        if not os.path.isfile(curdir+'/apps/'+p+'.apk'):
            url = packageinfo_get_getpkg(p, False)
            if url :
                logging.info('Downloading ')
                sp = curdir+'/apps/'+p
                if downloadFile(url, sp+'.tmp'):
                    ret = execShell('mv '+sp+'.tmp '+sp+'.apk')
                else:
                    logging.info('Downlod error ')
            else:
                logging.info('Get download url error')
        
        if not os.path.isfile(curdir+'/apps/'+p+'.apk'):
            #monkey after install
            #pkgList.remove(p)
            continue

        if installm.poll():
            installm = execShellDaemon(installmcmd)
        logging.info('Installing ')
        cmd = adb + ' install '+curdir+'/apps/'+p+'.apk'
        ret = execShell(cmd)
        if 'e' in ret.keys():
            logging.info(ret.get('e'))
        else:
            logging.info('Success')

    #清理monkey     
    installm.terminate()
    time.sleep(1)
    killMonkey(adb)

    logging.info('======Install done======')

def uninstallPkg(adb, pkgList, devicePkg):
    for p in pkgList:
        logging.info('Uninstalling '+p)
        if p in devicePkg:
            cmd = adb + '  shell pm  uninstall '+p
            ret = execShell(cmd)
            logging.info(ret.get('d'))
        else:
            logging.info("not installed ")

def checkOnline(deviceid=''):
    devices = execShell('adb devices -l').get('d')
    if deviceid:
        if devices.find(deviceid) != -1:
            return True
        else:
            print('Device id error')
            print(execShell('adb devices').get('d'))
            return False
    else:
        if devices.count('device ') == 0:
            print('No device')
            return False
        elif devices.count('device ') == 1:
            return True
        elif devices.count('device ') > 1:
            print('More than one device, please set -s deviceid')
            return False

def getPkgListFile(p):
    if os.path.isfile(p):
        try:
            with open(p, 'r') as f:
                pkgs = f.read().split('\n')
        except Exception as e:
            logging.info(str(e))
            pkgs = []
    else:
        pkgs = p.split(',')
    pkg = []
    for p in pkgs:
        if p:
            pkg.append(p.strip())
    return pkg

def getDevicePkgs(adb):
    ret = execShell(adb + ' shell pm list packages')
    pkgs = []
    if 'e' not in ret.keys():
        dt = ret.get('d').split('\n')
        for p in dt:
            if p:
                pkgs.append(p.split(':')[1])
    else:
        logging.info(ret.get('e'))
    return pkgs
    
def getPkgListInternet(pkg):
    return packageinfo_get_getpkg(pkg, True)

def timeoutKIll(adb, p, t):
    for i in range(t):
        time.sleep(1)
    cmd = adb + ' shell "am force-stop '+p+' " '
    execShell(cmd)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='批量启动APP工具')
    parser.add_argument("-m", "--monkey", type=str, help="monkey测试，输入包名或文件名(包名以逗号分隔，文件中按行保存)")
    parser.add_argument("-i", "--install", type=str, help="批量安装，输入包名或文件名")
    parser.add_argument("-u", "--uninstall", type=str, help="批量卸载，输入包名或文件名")
    parser.add_argument("-l", "--lists", type=str, help="搜索包名相关APP，输入包名前缀或完整包名")
    parser.add_argument("-d", "--download", type=str, help="批量下载，输入包名或文件名")
    parser.add_argument("-s", "--deviceid", type=str, help="指定设备（连接多个手机情况下）")
    parser.add_argument("-c", "--clean", action="store_true", help="清理残余进程")
    
    if sys.version_info.major != 3:
        print('Run with python3')
        sys.exit()
        
    args = parser.parse_args()
    monkey = args.monkey
    install = args.install
    uninstall = args.uninstall
    lists = args.lists
    download = args.download
    deviceid = args.deviceid
    clean = args.clean

    #支持多手机连接情况
    _adb_ = 'adb'
    _deviceid_ = deviceid
    #检测手机
    if not checkOnline(_deviceid_):
        parser.print_help()
        sys.exit()
    if _deviceid_:
        _adb_ += ' -s '+deviceid

    try:
        #获取设备pkgs
        devicePkg = getDevicePkgs(_adb_)
        if len(devicePkg) < 3:
            logging.error('Device error')
            sys.exit()
        
        curdir = os.path.dirname(os.path.abspath(__file__))
        if monkey:
            pkgs = getPkgListFile(monkey)
            startMonekyTest(_adb_, pkgs, devicePkg, _deviceid_)

        elif install:
            pkgs = getPkgListFile(install)
            installPkg(_adb_, pkgs, devicePkg)

        elif uninstall:
            pkgs = getPkgListFile(uninstall)
            uninstallPkg(_adb_, pkgs, devicePkg)

        elif lists:
            print(getPkgListInternet(lists))

        elif download:
            pkgs = getPkgListFile(download)
            downloadPkgList(_adb_, pkgs, devicePkg)

        elif clean:
            killMonkey(_adb_)

        else:
            parser.print_help()
    except KeyboardInterrupt:
        logging.info('Ctrl+C')
        killMonkey(_adb_)