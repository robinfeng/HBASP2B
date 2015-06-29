# Learn the Git on Mac OS X
## 1. 在 Mac OS X 上安装 SourceTree
1. 打开 App Store
2. 搜索 SourceTree
3. 点击“获取”进行安装

------

## 2. 在 SourceTree 创建一个代码库 Repository
### (1) 设置 GitHub 账号

1. 打开 SourceTree
2. 确定 Bookmarks 窗口已打开，菜单：View > Show Bookmarks
3. 右键菜单：New > Repository…
4. 在 Clone Repository 中，点击“地球”图标
5. 点击“Edit Accounts...”按钮
6. 点击“Add Account...”按钮
7. 输入或选择以下设置：
	- i. Hosting Service: GitHub
	- ii. Host URL: https://github.com
	- iii. Username:
	- xi. Preferred protocol: HTTPS
	- xii. Show private repositories: 选中
8. 点击“OK”，你会看到你的账号显示在列表中
9. 点击“Close”，你会看到你在GitHub中创建的项目
10. 选中相应的项目，点击“Create New Repository”
11. 指定Destination Path至本地工作路径
12. 点击“Clone”

------

## 3. 编辑本文档
1. 确定 Bookmarks 窗口已打开，菜单：View > Show Bookmarks
2. 在刚才创建的代码库上点击右键菜单：Show in Finder
3. 编辑README.md，为了方便预览，我用 Mou 来编辑 MD 文档。

------

## 4. 提交至 master 
1. 确定 Bookmarks 窗口已打开，菜单：View > Show Bookmarks
2. 在刚才创建的代码库上点击右键菜单：Open
3. 切换至 Log View，菜单 View > Log View
4. 选中刚才编辑的 README.md，可以在右下角进行预览
5. 点击“Commit”按钮
6. 在 Commit message 文本框中输入备注：通过 SourceTree 提交README.md文档。
7. 点击“Commit”按钮
8. 查看 master 分支
- 在左边 BRANCHES 菜单的右边，点击 Show
- 你可以看到 master 分支，以及你修改的历史和 README.md 文档

------

## 5. 推送至 GitHub
1. 点击 Push 图标，或者使用菜单：Repository > Push…
2. 确认选择 origin 代码库
3. 勾选 master 分支
4. 点击 OK 按钮

------

## 6. 检查是否成功推送至 GitHub
1. 菜单：View > Show Hosted Repositories
2. 选择此项目 LearnGit，点击右键
3. 点击 Open in Browser...
4. 检查最新的更新已经发布至 GitHub

------

## 7. 创建新的分支
1. 菜单：Repository > Branch...
2. 点击 New Branch 按钮
3. 在 New Branch 文本框输入：Dev_1.0
4. 点击 Create Branch 按钮
5. 在 BRANCHES 下，会看到当前分支被自动切换至 Dev_1.0
6. 参考 4. 提交至 master，将其提交至 GitHub

------
## 8. 为新分支创建一个新的文档
1. 参考第 3 小节，创建一个新的文档 Dev 1.0.md
2. 将此文件 Add 并 Commit

## 9. 推送新的代码至 GitHub 的新建分支 Dev_1.0
1. 菜单：Repository > Push...
2. 勾选 Dev_1.0 分支，Remote branch 选择 Dev_1.0
3. 点击 OK

