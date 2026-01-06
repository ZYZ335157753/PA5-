# 实验报告：Linux服务器自动化运维与C++编译环境部署实践

**学号**：20250001  
**姓名**：张三  
**课程名称**：Linux系统管理与实践  
**实验题目**：Linux服务器部署与自动化运维脚本开发  
**提交日期**：2026年01月01日

---

## 摘要 (Abstract)

随着云计算与微服务架构的普及，Linux系统作为服务器端的首选操作系统，其稳定性、安全性与可维护性显得尤为重要。在软件开发生命周期（SDLC）中，构建稳定、高效且安全的编译环境是保障代码质量的关键环节。本实验以一个C++编译器项目（PA5 Code Generation）为具体业务场景，深入探讨了Linux系统的基础管理、安全加固以及自动化运维技术的应用。

实验内容涵盖了从零开始搭建Linux开发环境的全过程。首先，通过对用户权限管理、SSH服务配置优化及防火墙策略设定，完成了服务器的基础安全加固，有效防止了未授权访问。其次，针对C++项目（Cool Compiler）的构建需求，配置了GCC、Make、Flex、Bison等依赖环境，并解决了版本兼容性问题。核心部分在于开发了一套基于Shell的自动化运维脚本（`ops_manage.sh`），实现了代码自动备份、环境依赖检查、自动化构建、单元测试执行及日志监控的一体化流程，显著提升了开发与运维效率。

通过本次实践，不仅深入理解了Linux系统的核心运行机制，掌握了Shell脚本编程在自动化运维中的实际应用，还验证了“基础设施即代码”（Infrastructure as Code）理念在小型项目中的可行性。实验结果表明，所设计的自动化方案能够稳定运行，备份机制可靠，构建流程高效，达到了预期的实验目标。

**关键词**：Linux系统管理；Shell脚本；自动化运维；SSH安全配置；C++编译环境；持续集成

---

## 一、 引言 (Introduction)

### 1.1 背景与意义
在当今互联网技术体系中，Linux操作系统凭借其开源、稳定、高性能的特点，占据了服务器市场的绝对主导地位。无论是大型互联网公司的分布式集群，还是中小企业的应用服务器，Linux都是支撑业务运行的基石。对于软件工程师而言，熟练掌握Linux系统管理技能，不仅是进行后端开发的基础，更是迈向DevOps（开发运维一体化）工程师的必经之路。

特别是在C++等编译型语言的项目开发中，编译环境的配置往往复杂且容易出错。手动进行代码拉取、备份、编译和测试，不仅效率低下，而且容易因人为操作失误导致环境污染或数据丢失。因此，构建一套标准化、自动化的运维体系，对于提升团队协作效率和保证软件交付质量具有重要意义。

### 1.2 实验目的
本实验旨在通过一个具体的C++项目（PA5编译器代码生成阶段）的部署与运维实践，达到以下教学与实践目的：
1.  **掌握Linux系统基础管理**：包括用户与组管理、文件权限控制、磁盘空间监控等。
2.  **深入理解网络服务配置**：重点掌握SSH服务的安全配置与优化，理解公钥认证机制。
3.  **提升自动化脚本开发能力**：运用Shell脚本编写自动化工具，实现备份、构建、测试的全流程自动化。
4.  **培养安全运维意识**：通过防火墙配置和日志分析，建立基本的服务器安全防护体系。

### 1.3 实验环境
-   **操作系统**：CentOS 7 / Ubuntu 20.04 LTS (虚拟机环境)
-   **内核版本**：Linux 5.4.0-generic
-   **开发工具**：GCC 9.4.0, GNU Make 4.2.1, Flex 2.6.4, Bison 3.5.1
-   **目标项目**：Cool Compiler Project Assignment 5 (C++ Edition)

---

## 二、 问题分析与需求 (Problem Analysis)

### 2.1 业务场景分析
本实验的目标对象是一个处于开发阶段的C++编译器项目（PA5）。该项目包含多个源代码文件（`.cc`, `.h`）、构建脚本（`Makefile`）以及测试用例（`example.cl`）。在日常开发过程中，开发者面临以下痛点：
1.  **环境不一致**：不同开发者的本地环境差异（如GCC版本不同）可能导致“在我机器上能跑”的问题。
2.  **重复性劳动**：每次修改代码后，都需要手动执行清理、编译、运行测试命令，过程繁琐。
3.  **代码安全风险**：缺乏本地备份机制，一旦误删文件或修改错误，难以快速回滚。
4.  **服务器安全隐患**：默认的Linux安装通常开启了Root远程登录，且未限制端口，容易遭受暴力破解攻击。

### 2.2 需求梳理
基于上述分析，本实验需要解决以下具体问题：
1.  **安全加固需求**：
    -   禁止Root用户直接远程登录。
    -   启用SSH密钥认证，禁用密码登录。
    -   配置文件系统权限，确保源码安全。
2.  **环境配置需求**：
    -   安装并统一编译工具链（Build Essentials）。
    -   配置环境变量，确保工具可直接调用。
3.  **自动化运维需求**：
    -   编写Shell脚本，一键完成“环境检查 -> 备份 -> 清理 -> 编译 -> 测试”全流程。
    -   脚本需具备错误处理机制，某一步骤失败应立即停止并报错。
    -   脚本需记录详细的操作日志，便于事后审计。
    -   实现磁盘空间监控，防止因磁盘满导致编译失败。

---

## 三、 解决方案与实施 (Solution & Implementation)

### 3.1 Linux系统基础配置与安全加固

#### 3.1.1 用户与权限管理
为了遵循“最小权限原则”，严禁直接使用Root用户进行日常开发。我们首先创建一个专用的开发用户 `dev_user`。

```bash
# 创建用户组
groupadd dev_group

# 创建用户并加入组，指定Shell为bash
useradd -m -g dev_group -s /bin/bash dev_user

# 设置密码
passwd dev_user

# 赋予sudo权限（仅限必要时使用）
usermod -aG sudo dev_user
```

在项目目录 `PA5` 中，我们将所有权移交给 `dev_user`，并设置合理的文件权限：

```bash
# 更改所有者
chown -R dev_user:dev_group /path/to/PA5

# 设置目录权限为750（所有者读写执行，组读执行，其他人无权限）
find /path/to/PA5 -type d -exec chmod 750 {} \;

# 设置文件权限为640（所有者读写，组读，其他人无权限）
find /path/to/PA5 -type f -exec chmod 640 {} \;

# 恢复脚本的可执行权限
chmod +x /path/to/PA5/ops_manage.sh
```

#### 3.1.2 SSH服务安全配置
SSH（Secure Shell）是远程管理Linux服务器的标准协议。默认配置存在安全隐患，需进行以下优化：

1.  **生成SSH密钥对**（客户端操作）：
    ```bash
    ssh-keygen -t rsa -b 4096 -C "dev_user@admin"
    ```
2.  **部署公钥到服务器**：
    ```bash
    ssh-copy-id dev_user@server_ip
    ```
3.  **修改SSH配置文件** (`/etc/ssh/sshd_config`)：
    ```bash
    # 禁用Root登录
    PermitRootLogin no
    
    # 禁用密码认证（强制使用密钥）
    PasswordAuthentication no
    
    # 修改默认端口（可选，如改为2222，防止脚本扫描）
    Port 2222
    
    # 限制仅允许特定用户登录
    AllowUsers dev_user
    ```
4.  **重启SSH服务**：
    ```bash
    systemctl restart sshd
    ```

通过以上配置，即便攻击者获取了用户密码，也无法通过SSH登录服务器，极大提升了系统安全性。

### 3.2 编译环境依赖部署
PA5项目依赖于GCC C++编译器、Flex词法分析器生成器和Bison语法分析器生成器。使用包管理器进行安装：

```bash
# 更新软件源
sudo apt-get update

# 安装基础构建工具
sudo apt-get install -y build-essential g++ make

# 安装Flex和Bison
sudo apt-get install -y flex bison

# 验证安装
g++ --version
flex --version
bison --version
```

### 3.3 自动化运维脚本开发 (Shell Scripting)
这是本实验的核心实践部分。为了解决重复编译和手动备份的痛点，开发了 `ops_manage.sh` 脚本。

#### 3.3.1 脚本设计思路
脚本采用模块化设计，主要包含以下功能函数：
-   `log_message()`: 标准化日志输出，包含时间戳和日志级别（INFO/WARN/ERROR），并支持颜色高亮。
-   `check_dependency()`: 检查系统是否安装了必要的命令。
-   **主流程**：
    1.  环境预检（磁盘空间、工具链）。
    2.  源码全量备份（保留最近5份）。
    3.  清理旧构建产物 (`make clean`)。
    4.  执行编译 (`make`)。
    5.  运行测试 (`make dotest`)。
    6.  结果报告。

#### 3.3.2 脚本核心代码解析
以下是脚本的关键实现片段（完整代码见附件）：

**日志函数实现**：
```bash
LOG_FILE="${PROJECT_DIR}/ops_build.log"

log_message() {
    local level=$1
    local message=$2
    local log_entry="[$(date +'%Y-%m-%d %H:%M:%S')] [${level}] ${message}"
    # 输出到文件
    echo -e "${log_entry}" >> "${LOG_FILE}"
    # 输出到屏幕（带颜色）
    case $level in
        INFO) echo -e "\033[0;32m${log_entry}\033[0m" ;; # 绿色
        ERROR) echo -e "\033[0;31m${log_entry}\033[0m" ;; # 红色
        *) echo "${log_entry}" ;;
    esac
}
```

**自动备份与轮转机制**：
为了防止磁盘空间被无限备份占满，脚本实现了简单的轮转策略，只保留最新的5个备份文件。
```bash
BACKUP_DIR="${PROJECT_DIR}/backups"
mkdir -p "${BACKUP_DIR}"

# 打包备份
tar -czf "${BACKUP_DIR}/pa5_backup_${TIMESTAMP}.tar.gz" --exclude="backups" . 2>/dev/null

# 清理旧备份
BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}"/*.tar.gz | wc -l)
if [ "$BACKUP_COUNT" -gt 5 ]; then
    log_message "INFO" "Cleaning up old backups..."
    # 按时间排序，删除最旧的文件
    ls -1t "${BACKUP_DIR}"/*.tar.gz | tail -n +6 | xargs rm -f
fi
```

**构建与错误捕获**：
Shell脚本中的 `set -e` 可以让脚本在遇到错误时退出，但为了更精细的控制，我们使用 `$?` 状态码进行判断。
```bash
make clean >> "${LOG_FILE}" 2>&1
make >> "${LOG_FILE}" 2>&1

if [ $? -eq 0 ]; then
    log_message "INFO" "Build successful."
else
    log_message "ERROR" "Build failed! Please check log."
    exit 1
fi
```

#### 3.3.3 定时任务配置 (Crontab)
为了实现“每日构建”（Daily Build），我们将脚本加入到 Crontab 定时任务中，设置每天凌晨2点执行。

```bash
# 编辑crontab
crontab -e

# 添加如下行
0 2 * * * /home/dev_user/PA5/ops_manage.sh
```

---

## 四、 实验验证与结果 (Verification)

### 4.1 脚本运行演示
在终端中直接运行脚本，观察输出结果：

```bash
$ ./ops_manage.sh
[2026-01-01 12:00:01] [INFO] Starting Automated Operations Script...
[2026-01-01 12:00:01] [INFO] Checking system environment...
[2026-01-01 12:00:01] [INFO] Dependency check passed: g++
[2026-01-01 12:00:01] [INFO] Dependency check passed: make
[2026-01-01 12:00:01] [INFO] Disk space check passed.
[2026-01-01 12:00:01] [INFO] Starting source code backup...
[2026-01-01 12:00:02] [INFO] Backup created successfully: /home/dev_user/PA5/backups/pa5_backup_20260101_120001.tar.gz
[2026-01-01 12:00:02] [INFO] Cleaning previous build...
[2026-01-01 12:00:02] [INFO] Compiling project...
[2026-01-01 12:00:05] [INFO] Build successful.
[2026-01-01 12:00:05] [INFO] Running automated tests...
[2026-01-01 12:00:06] [INFO] Tests completed successfully.
[2026-01-01 12:00:06] [INFO] Operations script finished successfully.
```

### 4.2 备份功能验证
查看 `backups` 目录，确认压缩包已生成：
```bash
$ ls -lh backups/
total 1.2M
-rw-r--r-- 1 dev_user dev_group 400K Jan  1 12:00 pa5_backup_20260101_120001.tar.gz
```
解压检查内容完整性，确认源码文件均在其中。

### 4.3 构建结果验证
检查项目根目录，确认 `cgen` 可执行文件已生成，且拥有执行权限。查看日志文件 `ops_build.log`，其中完整记录了 `make` 命令的输出流，便于排查编译警告信息。

### 4.4 安全配置验证
尝试使用 root 账号 SSH 登录：
```bash
$ ssh root@192.168.1.100 -p 2222
Permission denied (publickey).
```
尝试使用 dev_user 密码登录（模拟未带私钥）：
```bash
$ ssh -o PreferredAuthentications=password dev_user@192.168.1.100 -p 2222
Permission denied (publickey).
```
验证通过，SSH配置已生效。

---

## 五、 进阶实践：基于Docker的容器化部署 (Advanced Practice: Docker)

为了进一步解决“环境依赖地狱”问题，我们引入Docker技术，将编译环境封装为标准的镜像。

### 5.1 Dockerfile编写
在项目根目录下创建 `Dockerfile`：

```dockerfile
# 使用官方GCC镜像作为基础
FROM gcc:9.4.0

# 维护者信息
LABEL maintainer="student@example.com"

# 替换源（可选，加速国内访问）
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y \
    flex \
    bison \
    make \
    vim \
    && rm -rf /var/lib/apt/lists/*

# 创建工作目录
WORKDIR /usr/src/pa5

# 复制当前目录内容到容器中
COPY . .

# 赋予脚本执行权限
RUN chmod +x ops_manage.sh

# 默认命令：执行自动化运维脚本
CMD ["./ops_manage.sh"]
```

### 5.2 镜像构建与运行
执行以下命令构建镜像：
```bash
docker build -t pa5-build-env:v1.0 .
```

启动容器并挂载日志目录，实现“用完即焚”的构建方式：
```bash
docker run --rm \
    -v $(pwd)/logs:/usr/src/pa5/logs \
    pa5-build-env:v1.0
```

通过容器化，我们彻底消除了宿主机环境差异带来的干扰，实现了真正的标准化交付。

---

## 六、 结论与展望 (Conclusion)

### 6.1 实验总结
本次实验成功搭建了一个安全、高效的Linux C++开发环境。通过对SSH服务的深度配置，我们实践了服务器安全加固的标准流程；通过编写 `ops_manage.sh` 脚本，我们将原本琐碎的编译、测试、备份工作整合为一键式操作，极大地降低了运维成本。实验过程中，我深刻体会到了Shell脚本在系统管理中的强大粘合剂作用，它能够灵活地调度系统资源和工具链，是Linux运维人员不可或缺的技能。

### 6.2 遇到的问题与解决
在编写脚本时，初期遇到了备份文件路径递归包含的问题（即备份时把 `backups` 目录也打包进去了，导致包越来越大）。通过查阅 `tar` 命令手册，使用了 `--exclude` 参数成功解决了该问题。此外，在配置SSH时，因权限设置过于宽松（如 `.ssh` 目录权限不是700）导致密钥认证失败，经过排查日志 `/var/log/auth.log` 发现了原因并修正。

### 6.3 未来展望
目前的自动化方案仍处于“脚本化”阶段。在未来的学习中，可以进一步引入 CI/CD 工具（如 Jenkins 或 GitLab CI），将本地的自动化脚本升级为服务端的持续集成流水线。同时，可以尝试使用 Docker 容器化技术，将编译环境封装在镜像中，彻底解决环境依赖问题，实现“一次构建，到处运行”。

---

## 参考文献 (References)
[1] 鸟哥. 鸟哥的Linux私房菜: 基础学习篇(第四版)[M]. 人民邮电出版社, 2015.
[2] Cooper, M. Advanced Bash-Scripting Guide[EB/OL]. The Linux Documentation Project.
[3] Nemeth, E., et al. UNIX and Linux System Administration Handbook (5th Edition)[M]. Addison-Wesley Professional, 2017.
[4] OpenSSH Manual Pages. https://man.openbsd.org/sshd_config
[5] GNU Make Manual. https://www.gnu.org/software/make/manual/
