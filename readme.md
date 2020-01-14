# 功能
- Android APP monkey安全测试，可批量操作
- 支持MIUI系统APP及线上APP

# 使用
- Usage: python3 appstarter.py -h
- 需要配置PC及手机frida环境
- 需要开启USB调试、USB安装、USB调试(安全设置)
- 配置手机代理到mitmproxy，可发现安全漏洞
    
# 其他
- **防monkey点击导致断网等误点击，可以调整手机界面布局/增加点击深度: 顶部wifi放置最后/左下角电话、短信按钮移走**
- 经过MI5/MI8和Ubuntu/Win10测试