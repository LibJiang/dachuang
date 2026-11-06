# GitHub 与 Git 一天上手指南（零基础版）

> 适用对象：完全没用过 Git / GitHub 的队友。
> 目标：一天之内能独立完成「克隆仓库 → 改文件 → 提交 → 推送 → 拉取 → 开分支 → 发 PR → 解决冲突」。
> 使用方式：**每一关都有「学习门槛」，必须亲手做到才能进入下一关**。做不到就留在原地练，不要跳关。
> 环境：Windows + Git + GitHub Desktop（图形界面为主，命令行作为对照）。总时长约 7~8 小时。

---

## 时间安排（建议）

| 时间段 | 内容 |
|---|---|
| 09:00–09:20 | 第 0 关：概念 |
| 09:20–10:00 | 第 1 关：安装与账号 |
| 10:00–10:30 | 第 2 关：仓库权限与克隆 |
| 10:30–11:15 | 第 3 关：第一次提交 |
| 11:15–12:00 | 第 4 关：推送与拉取 |
| 13:30–14:30 | 第 5 关：分支与 Pull Request |
| 14:30–15:15 | 第 6 关：解决冲突 |
| 15:15–15:45 | 第 7 关：撤销与恢复 |
| 15:45–16:15 | 第 8 关：团队协作规范 |
| 16:15–17:00 | 结业任务 |

---

## 第 0 关：先搞清楚 Git 和 GitHub 是什么（20 分钟）

**要理解的三件事**

1. **Git**：装在你电脑上的「版本管理工具」，负责记录文件的每一次修改（谁、什么时候、改了什么）。
2. **GitHub**：一个网站，用来存放 Git 仓库，方便多人在线协作、备份、展示。
3. **三个核心动作**：
   - `commit`（提交）：把本地修改存成一个「快照」，记录在本地历史里。
   - `push`（推送）：把本地提交上传到 GitHub。
   - `pull`（拉取）：把 GitHub 上的新提交下载到本地。

**类比**：Git 是「存档功能」，GitHub 是「云存档网站」，commit 是存一个档，push 是上传存档，pull 是下载别人的存档。

【学习门槛 0】
不看资料，用自己的话向队友解释清楚：
- Git 和 GitHub 的区别
- commit / push / pull 各是做什么的

三题都答对 → 过关。

---

## 第 1 关：安装工具、注册账号、配置身份（40 分钟）

### 1.1 安装

- Git：<https://git-scm.com/download/win>（一路默认下一步即可）
- GitHub Desktop：<https://desktop.github.com/>（推荐新手先用它）

### 1.2 注册 GitHub 账号

- 打开 <https://github.com/signup>，用邮箱注册，记住用户名和密码。
- 建议同时申请 GitHub Student Pack（学生免费福利）：<https://education.github.com/>

### 1.3 配置 Git 身份（只需一次）

打开 PowerShell，执行（把名字和邮箱换成你自己的）：

```powershell
git config --global user.name "你的名字"
git config --global user.email "你的邮箱@example.com"
```

### 1.4 登录 GitHub Desktop

打开 GitHub Desktop → `File → Options → Accounts → Sign in`，用浏览器授权登录。

【学习门槛 1】
- 终端执行 `git --version` 能显示版本号
- `git config --global user.name` 和 `user.email` 能显示你配置的值
- GitHub Desktop 左上角显示你的账号头像，且已登录

三项全部满足 → 过关。

---

## 第 2 关：拿到仓库权限并克隆到本地（30 分钟）

### 2.1 让仓库管理员给你权限（关键）

仓库是 `LibJiang/dachuang`。**公开仓库人人可看，但只有协作者能推送。**

管理员操作：
1. 打开 <https://github.com/LibJiang/dachuang>
2. `Settings → Collaborators → Add people`
3. 输入队友的 GitHub 用户名，发送邀请

队友操作：
- 查收 GitHub 邮件或打开仓库页面，点 **Accept invitation**。

> 如果没有协作者权限，就只能用「Fork → 改 → Pull Request」的方式贡献（见第 5 关）。小团队建议直接加协作者。

### 2.2 克隆仓库

方式 A（GitHub Desktop，推荐）：
1. `File → Clone repository`
2. 选 `GitHub.com` 标签，找到 `LibJiang/dachuang`
3. Local path 选一个目录（如 `C:\Users\你的用户名\source\repos`）
4. 点 **Clone**

方式 B（命令行）：

```powershell
cd C:\Users\你的用户名\source\repos
git clone https://github.com/LibJiang/dachuang.git
```

### 2.3 用 VS Code 打开

VS Code → `文件 → 打开文件夹` → 选择 `dachuang` 文件夹。

【学习门槛 2】
- 本地文件夹里能看到 `README.md`、`LICENSE`、`docs/`
- GitHub Desktop 左侧显示该仓库
- 终端进入该目录执行 `git log --oneline`，至少能看到 1 条提交记录

三项全部满足 → 过关。

---

## 第 3 关：第一次修改并提交（45 分钟）

### 3.1 做一个小改动

在 `docs/` 下新建一个文件 `notes-你的名字.md`，写一句话，例如：

```markdown
# 张某某的学习笔记
今天我学会了 clone 和 commit。
```

### 3.2 提交（commit）

方式 A（GitHub Desktop）：
1. 左侧 `Changes` 会列出新文件
2. 左下 `Summary` 填：`docs: 添加张某某的学习笔记`
3. 点 **Commit to main**

方式 B（命令行）：

```powershell
cd C:\Users\你的用户名\source\repos\dachuang
git add .
git commit -m "docs: 添加张某某的学习笔记"
```

### 3.3 理解「提交信息」规范

推荐格式：`类型: 简短说明`
- `docs:` 文档
- `feat:` 新功能
- `fix:` 修复
- `chore:` 杂项

【学习门槛 3】
- GitHub Desktop 的 `History` 里能看到你刚提交的记录
- `git log --oneline` 最新一条是你的提交
- `git status` 显示工作区干净（working tree clean）

三项全部满足 → 过关。

---

## 第 4 关：推送与拉取（45 分钟）

### 4.1 推送（push）

方式 A（GitHub Desktop）：点顶部 **Push origin**。
方式 B（命令行）：`git push`

然后打开 <https://github.com/LibJiang/dachuang>，确认能看到你新建的文件。

### 4.2 拉取（pull）

让队友（或管理员）在 GitHub 网页上改一下 `README.md` 并提交，然后你：

方式 A（GitHub Desktop）：点 **Fetch origin**，再点 **Pull origin**。
方式 B（命令行）：`git pull`

【学习门槛 4】
- GitHub 网页上能看到你推送的文件
- 你能把别人的远程修改拉取到本地，并在 VS Code 里看到变化
- `git status` 显示 `Your branch is up to date with 'origin/main'`

三项全部满足 → 过关。

---

## 第 5 关：分支与 Pull Request（60 分钟）

### 5.1 为什么用分支

分支 = 从主线复制出一条「平行世界」，在上面随便改，不影响 `main`，改好再合并。

### 5.2 创建分支并修改

方式 A（GitHub Desktop）：
1. 顶部 `Current branch → New branch`
2. 名字：`feature/你的名字-测试`
3. 修改一个文件，Commit
4. 点 **Publish branch**（推送分支）

方式 B（命令行）：

```powershell
git checkout -b feature/你的名字-测试
# 修改文件
git add .
git commit -m "feat: 测试分支修改"
git push -u origin feature/你的名字-测试
```

### 5.3 发起 Pull Request（PR）

1. 打开 GitHub 仓库页面，会提示 `Compare & pull request`
2. 填写标题和说明，点 **Create pull request**
3. 点 **Merge pull request → Confirm merge**
4. 回到本地，切回 main 并拉取最新代码

```powershell
git checkout main
git pull
```

【学习门槛 5】
- 成功创建过一个 PR
- PR 被合并（自己合并也可以）
- 本地切回 `main` 后 `git pull`，能看到刚才分支里的修改

三项全部满足 → 过关。

---

## 第 6 关：解决一次冲突（45 分钟）

### 6.1 制造冲突

1. 队友在网页上把 `README.md` 的某一行改成 A，提交。
2. 你在本地把**同一行**改成 B，提交。
3. 你先 `git pull`，此时会提示冲突（conflict）。

### 6.2 解决冲突

VS Code 会在冲突文件里显示：

```
<<<<<<< HEAD
你的修改
=======
队友的修改
>>>>>>> origin/main
```

处理方式：删掉 `<<<<<<<`、`=======`、`>>>>>>>` 这些标记，保留你想要的内容，保存。

然后：

方式 A（GitHub Desktop）：在 `Changes` 里勾选已解决，Commit。
方式 B（命令行）：

```powershell
git add README.md
git commit -m "fix: 解决 README 冲突"
git push
```

【学习门槛 6】
- 能独立看懂冲突标记
- 能保留正确内容并完成一次冲突提交
- `git status` 不再显示冲突

三项全部满足 → 过关。

---

## 第 7 关：撤销与恢复（30 分钟）

### 7.1 撤销未提交的修改

```powershell
git restore 文件名        # 丢弃某个文件的修改
git restore .             # 丢弃所有未提交修改（慎用）
```

### 7.2 撤销一次已提交但未推送的记录

```powershell
git reset --soft HEAD~1   # 撤销提交，修改仍在工作区
```

### 7.3 撤销已推送的提交

```powershell
git revert <提交ID>       # 生成一条反向提交，安全
```

> 记住：**已经 push 的提交不要用 `reset --hard` 硬删历史**，用 `revert`。

【学习门槛 7】
- 能撤销一个未提交的修改
- 能说清 `restore` / `reset --soft` / `revert` 三者的区别
- 能对一次提交执行 `revert` 并推送

三项全部满足 → 过关。

---

## 第 8 关：团队协作规范（15 分钟）

本仓库约定：

1. **每天开工先 `pull`，收工前 `push`。**
2. **不在 `main` 上直接改大功能**，先开分支（`feature/xxx`、`fix/xxx`）。
3. **提交信息写清楚**：`docs: 补充 HQC 背景`，不要写 `update`、`123`。
4. **不要提交**：编译产物（`*.bit`、`*.jou`、`build/`）、大文件（视频）、密钥 / Token。
5. **改同一个文件前先沟通**，减少冲突。
6. 重要修改走 PR，让队友看一眼再合并。

【学习门槛 8】
- 不看资料，能复述上面 6 条规则
- 能说出本项目哪些文件「不应该提交」

两题都答对 → 过关。

---

## 结业任务（1 小时，必须完成）

在仓库里完成一次真实贡献：

1. 从 `main` 新建分支 `notes/你的名字`
2. 新建 `docs/notes-你的名字.md`，内容包括：
   - 你的姓名 / 学号
   - 今天学会的 5 条 Git 命令
   - 一句话总结「Git 和 GitHub 的区别」
3. 提交并推送
4. 发起 PR 并合并
5. 回到本地 `main` 执行 `git pull`，确认文件已同步

**通过标准**：GitHub 网页上能看到你的文件，且你能独立复述整个流程。

---

## 附录 A：命令速查表

| 目的 | 命令 |
|---|---|
| 查看状态 | `git status` |
| 查看历史 | `git log --oneline` |
| 拉取 | `git pull` |
| 添加改动 | `git add .` |
| 提交 | `git commit -m "说明"` |
| 推送 | `git push` |
| 新建并切换分支 | `git checkout -b 分支名` |
| 切换分支 | `git checkout 分支名` |
| 查看分支 | `git branch` |
| 合并分支 | `git merge 分支名` |
| 撤销未提交修改 | `git restore 文件名` |
| 撤销提交（保留改动） | `git reset --soft HEAD~1` |
| 撤销已推送提交 | `git revert 提交ID` |

## 附录 B：GitHub Desktop 与命令对照

| 操作 | GitHub Desktop | 命令 |
|---|---|---|
| 克隆 | File → Clone repository | `git clone <url>` |
| 提交 | 填 Summary → Commit to main | `git commit -m` |
| 推送 | Push origin | `git push` |
| 拉取 | Fetch origin → Pull origin | `git pull` |
| 新建分支 | Current branch → New branch | `git checkout -b` |
| 发 PR | 网页 Compare & pull request | 网页操作 |

## 附录 C：常见问题

1. **push 被拒（rejected）**：远程有你的本地没有的提交，先 `git pull --rebase origin main`，再 `git push`。
2. **认证失败**：GitHub Desktop 重新登录；命令行会弹出浏览器授权，按提示操作。不要用账号密码，GitHub 已不支持密码推送。
3. **换行符警告（LF/CRLF）**：Windows 上常见，可设置 `git config --global core.autocrlf true`。
4. **误提交大文件**：GitHub 单文件上限 100MB，提交前检查；已提交的用 `git rm --cached 文件名` 移出版本库并写进 `.gitignore`。
5. **改乱了想重来**：先 `git status` 看清状态，再用 `restore` / `revert`，不要上来就 `reset --hard`。

## 附录 D：继续学习

- Git 官方中文书（Pro Git）：<https://git-scm.com/book/zh/v2>
- GitHub 官方文档：<https://docs.github.com/zh>
- GitHub Skills（互动课程）：<https://skills.github.com/>
- Learn Git Branching（可视化练习）：<https://learngitbranching.js.org/?locale=zh_CN>
- Oh My Git!（游戏化学习）：<https://ohmygit.org/>
- GitHub Student Pack：<https://education.github.com/>
