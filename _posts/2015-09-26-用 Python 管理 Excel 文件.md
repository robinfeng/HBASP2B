# 用 Python 管理 Excel 文件

**Chris Withers with help from John Machin EuroPython 2009, Birmingham**

**许可证**


## 介绍
此教程包含以下内容：

**xlrd**

* http://pypi.python.org/pypi/xlrd
* 读取和格式化 .xls 文件
* 此教程基于 0.7.1 版本
* 这里是 API 文档：https://secure.simplistix.co.uk/svn/xlrd/trunk/xlrd/doc/xlrd.html

**xlwt**
* http://pypi.python.org/pypi/xlwt
* 写入和格式化 .xls 文件
* 此教程基于 0.7.2 版本
* 这里是 API 文档：https://secure.simplistix.co.uk/svn/xlwt/trunk/xlwt/doc/xlwt.html
* 这里是实例：https://secure.simplistix.co.uk/svn/xlwt/trunk/xlwt/examples/

**xlutils**
* http://pypi.python.org/pypi/xlutils
* 一套用于 xlrd 和 xlwt 的工具：
	* 从原表格复制数据至目标表格
	* 从原表格过滤数据至目标表格
* 此教程基于 1.3.0 版本
* 这里是文档和实例：https://secure.simplistix.co.uk/svn/xlutils/trunk/xlutils/docs/

自动化处理 Excel 文件，仍然可能需要用到 COM：
* 操作图型
* 富文本单元格
* 读取单元格公式
* 操作宏
* 其它的 .xls 文件中复杂的工作

## 安装

## 读取 Excel 文件

### 打开工作簿

```
# open.py
from mmap import mmap,ACCESS_READfrom xlrd import open_workbookprint open_workbook('simple.xls')with open('simple.xls','rb') as f:    print open_workbook(        file_contents=mmap(f.fileno(),0,access=ACCESS_READ)        )aString = open('simple.xls','rb').read()print open_workbook(file_contents=aString)
```

### 遍历工作簿

```
# simple.py
from xlrd import open_workbookwb = open_workbook('simple.xls')for s in wb.sheets():    print 'Sheet:',s.name    for row in range(s.nrows):        values = []        for col in range(s.ncols):            values.append(s.cell(row,col).value)        print ','.join(values)print
```
