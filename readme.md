# 功能
- 批量安装并启动APP，触发APP尽可能多的功能
- 结合代理端的漏洞扫描功能，发现尽APP可能多的漏洞
- 批量测试MIUI系统APP及小米系APP

# 使用
- Usage: python3 run.py -h
- 退出: Ctrl+C
- pkglist-app.mi.com: 小米系APP
- pkglist-sys: MIUI系统APP
    
# ps
- 需要手机及电脑配有frida环境
- 需要开启USB调试、USB安装、USB调试(安全设置)
- 需要python3 with requests, beautifulsoup4
- 经过MI5/Redmi Y3/MI8测试
- **防monkey点击导致断网等误点击，可以调整手机界面布局/增加点击深度: 顶部wifi放置最后/左下角电话、短信按钮移走**
- 解决难点：绕过部分MIUI的USB安装管理，实现自动安装APP；hook方式解决权限申请弹框；frida绕过APP的SSL证书校验；设备掉线检查