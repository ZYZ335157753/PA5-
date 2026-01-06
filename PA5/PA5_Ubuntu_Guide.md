# PA5 实验操作手册 (Ubuntu版)

本手册专为在 Ubuntu 环境下完成 PA5 (Code Generator) 实验设计。请按照以下步骤一步步操作。

## 一、 环境准备 (Environment Setup)

在开始编写代码之前，必须确保你的开发环境已经链接了必要的 COOL 编译器组件（词法分析器、语法分析器、语义分析器）。

### 1.1 安装基础工具
确保你的 Ubuntu 系统安装了必要的编译工具：

```bash
sudo apt-get update
sudo apt-get install -y build-essential g++ make flex bison spim
```

### 1.2 链接编译器组件
PA5 需要依赖 `lexer`、`parser` 和 `semant` 的可执行文件。
我们提供了一个自动脚本 `setup_env.sh` 来完成此工作（假设你使用的是标准课程环境路径 `/usr/class/bin`）。

**操作步骤：**

1.  赋予脚本执行权限：
    ```bash
    chmod +x setup_env.sh
    ```

2.  运行脚本：
    ```bash
    ./setup_env.sh
    ```
    *(注：如果你没有使用标准环境，请指定二进制文件路径，例如：`./setup_env.sh /home/user/cool/bin`)*

3.  验证链接：
    执行 `ls -l`，你应该能看到 `lexer`、`parser`、`semant` 指向了正确的位置。

---

## 二、 编译与构建 (Compilation)

### 2.1 清理旧文件
每次重新开始或遇到奇怪的编译错误时，先执行清理：

```bash
make clean
```

### 2.2 编译代码生成器
编译你的 `cgen` 程序：

```bash
make cgen
```

如果编译成功，当前目录下会生成一个名为 `cgen` 的可执行文件。

*(注：如果遇到编译错误，请检查 `cgen.cc` 等文件是否缺失或有语法错误)*

---

## 三、 运行与测试 (Running & Testing)

PA5 的核心目标是将 COOL 源代码编译为 MIPS 汇编代码 (`.s` 文件)，并在 SPIM 模拟器上运行。

### 3.1 单步测试流程
假设你有一个测试文件 `example.cl`（当前目录下已包含）。

1.  **生成汇编代码**：
    将 COOL 源码通过完整管道处理，最终由你的 `cgen` 生成汇编：
    ```bash
    ./lexer example.cl | ./parser example.cl | ./semant example.cl | ./cgen > example.s
    ```
    *或者使用提供的脚本（如果配置正确）：*
    ```bash
    ./mycoolc example.cl
    ```
    这将生成 `example.s` 文件。

2.  **运行汇编代码**：
    使用 SPIM 模拟器运行生成的汇编代码：
    ```bash
    spim -file example.s
    ```
    你应该能看到程序的输出结果。

### 3.2 自动化对比测试
为了验证你的代码生成器是否正确，你需要将其输出与标准编译器的输出进行对比。

1.  **使用标准编译器生成基准**：
    *(假设标准编译器名为 `coolc`)*
    ```bash
    coolc example.cl
    spim -file example.s > expected.txt
    ```

2.  **使用你的编译器生成结果**：
    ```bash
    ./mycoolc example.cl -o my_example.s
    spim -file my_example.s > actual.txt
    ```

3.  **对比差异**：
    ```bash
    diff expected.txt actual.txt
    ```
    如果没有任何输出，说明你的实现与标准版本完全一致！

---

## 四、 开发指南 (Development Guide)

根据 `PA5指南.md`，你主要需要修改以下文件来完成实验：

1.  **`cgen.cc`**:
    *   这是核心文件。你需要在这里实现 `code()` 方法。
    *   重点关注 `CgenClassTable::code()` 和各种表达式节点（如 `plus_class`, `assign_class`）的 `code()` 方法。
    *   参考指南中的“代码生成流程”章节。

2.  **`cgen.h`**:
    *   如果需要添加新的成员变量或辅助函数，修改此文件。

3.  **`cool-tree.handcode.h`**:
    *   这里定义了 AST 节点的接口。通常不需要大幅修改，除非你需要为节点添加特殊的辅助方法。

**建议开发顺序：**
1.  先让最简单的程序（如打印整数）跑通。
2.  实现算术运算（`+`, `-`, `*`, `/`）。
3.  实现控制流（`if`, `while`）。
4.  实现方法调用（`dispatch`）。
5.  最后攻克对象初始化和继承。

---

## 五、 常用调试技巧 (Debugging)

*   **查看汇编代码**：不要只看运行结果，直接打开生成的 `.s` 文件查看 MIPS 代码，检查逻辑是否符合预期。
*   **使用 GDB**：
    ```bash
    gdb ./cgen
    run -d example.cl  # 开启调试模式运行
    ```
*   **打印调试信息**：在 `cgen.cc` 中使用 `if (cgen_debug) cout << "..." << endl;` 来输出调试信息（运行时需加 `-d` 参数）。

---

## 六、 提交前检查 (Final Check)

1.  确保所有测试用例都能通过 `diff` 测试。
2.  确保代码中没有硬编码的路径。
3.  执行 `make clean` 清理临时文件。
4.  打包提交（具体参照作业提交要求）。
