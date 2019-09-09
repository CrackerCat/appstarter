# 功能
- 批量安装并启动APP，触发APP尽可能多的功能
- 结合代理端的漏洞扫描功能，发现尽APP可能多的漏洞
- 批量测试MIUI系统APP及小米系APP

# 使用
- Usage: ./monkey.sh option 包名列表(逗号分割)
    - 1, -m 文件或包名列表  ->  monkey测试
    - 2, -i 文件或包名列表  ->  批量安装
    - 3, -u 文件或包名列表  ->  批量删除
    - 4, -l 包名或包名前缀  ->  搜索关联APP
    - 5, -x  ->  搜索xiaomi关联APP
    - 6, -c  ->  清理后台进程
- 退出: Ctrl+C
- pkglist-app.mi.com: 小米系APP
- pkglist-sys: MIUI系统APP
    
# ps
- 需要手机及电脑配有frida环境
- 需要开启USB调试、USB安装、USB调试(安全设置)
- 需要python3 with requests, beautifulsoup4
- 经过MI5/Redmi Y3/MI8测试
- **防monkey点击导致断网等误点击，可以调整手机界面布局/增加点击深度: 顶部wifi放置最后/左下角电话、短信按钮移走**
- 解决难点：绕过部分MIUI的USB安装管理，实现自动安装APP；自动点击权限申请弹框；frida绕过APP的SSL证书校验；设备掉线检查
- 待实现：启动所有导出组件，目前只有Activity