## 用 Windows task 实现在不同数据同时运行多个 Planned activity

参考：http://portal.beascloud.com/docs/help/online_eng/，Concenpts>Tasks

DB_1:

- Description: Task A
	* ID: 10
	* Type: Script
	* Execution:

```
#sqlupdate oitm set frgnname='CM00'where itemcode='CM00'#end
```
DB_2:

- Description: Task B
	* ID: 10
	* Type: Script
	* Execution:

```
#sqlupdate oitm set frgnname='CM11'where itemcode='CM11'#end
```

Windows Task:

- Task_1 对应 DB_1 的 Planned activity 10:

	* 程序或脚本: "C:\Program Files (x86)\beas software\beas\beas.exe"
	* 添加参数(可选): db=DB_1 user=manager pw=1111 task=10
	* 起始于(可选): C:\Program Files (x86)\beas software\beas\

- Task_2 对应 DB_2 的 Planned activity 10:

	* 程序或脚本: "C:\Program Files (x86)\beas software\beas\beas.exe"
	* 添加参数(可选): db=DB_2 user=manager pw=2222 task=10
	* 起始于(可选): C:\Program Files (x86)\beas software\beas\

*不足：Protocol 没有日志记录*