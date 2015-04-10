Learn the Git on Mac OS X
=======
### 1. 在 Mac OS X 上安装 SourceTree
=======
~~~~~~
a) 打开 App Store
b) 搜索 SourceTree
c) 点击“获取”进行安装
~~~~~~

### 2. 在 SourceTree 创建一个代码库 Repository
=======
#### (1) 设置 GitHub 账号
~~~~~~
a) 打开 SourceTree
b) 确定 Bookmarks 窗口已打开，菜单：View > Show Bookmarks
c) 右键菜单：New > Repository...
d) 在 Clone Repository 中，点击“地球”图标
e) 点击“Edit Accounts...”按钮
f) 点击“Add Account...”按钮
g) 输入或选择以下设置：
i. Hosting Service: GitHub
ii. Host URL: https://github.com
iii. Username:
xi. Preferred protocol: HTTPS
xii. Show private repositories: 选中
h) 点击“OK”，你会看到你的账号显示在列表中
i) 点击“Close”，你会看到你在GitHub中创建的项目
j) 选中相应的项目，点击“Create New Repository”
k) 指定Destination Path至本地工作路径
l) 点击“Clone”
~~~~~~
### 3. 编辑本文档
=======
~~~~~~
a) 确定 Bookmarks 窗口已打开，菜单：View > Show Bookmarks
b) 在刚才创建的代码库上点击右键菜单：Show in Finder
c) 编辑README.md，为了方便预览，我用 Mou 来编辑 MD 文档。
~~~~~~
### 4. 提交至 master 
=======
~~~~~~
a) 确定 Bookmarks 窗口已打开，菜单：View > Show Bookmarks
b) 在刚才创建的代码库上点击右键菜单：Open
c) 切换至 Log View，菜单 View > Log View
d) 选中刚才编辑的 README.md，可以在右下角进行预览
e) 点击“Commit”按钮
f) 在 Commit message 文本框中输入备注：通过 SourceTree 提交README.md文档。
g) 点击“Commit”按钮
h) 查看 master 分支
i. 在左边 BRANCHES 菜单的右边，点击 Show
ii. 你可以看到 master 分支，以及你修改的历史和 README.md 文档
~~~~~~
### 5. 推送至 GitHub