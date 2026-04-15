# remote-cluster-workflow

`remote-cluster-workflow` 是一个给 Codex 使用的 skill，用来把任务稳定地执行到用户自管的远端 Linux 服务器或 HPC 集群上，而不是只在本机运行。

它主要解决这些问题：

- 通过本地 `ssh` 连接远端
- 通过 remote profile 固定远端工作目录、环境激活方式和资源模板
- 在 login node、直连主机、Slurm `srun` 等场景下执行命令
- 在真正跑任务前先验证 profile 和环境
- 在高成本集群资源场景下避免盲猜 node、cores、partition、gpus、memory

## 仓库内容

这个仓库现在就是一个纯 skill 仓库，根目录就是正式 skill 来源。

主要文件和目录：

```text
remote-cluster-workflow/
  SKILL.md
  README.md
  test-prompts.json
  results.tsv
  agents/
  references/
  scripts/
```

其中：

- `SKILL.md`：skill 主说明
- `test-prompts.json`：dry-run 测试 prompt
- `results.tsv`：评估和优化记录
- `references/`：profile schema、示例和密码登录切换说明
- `scripts/`：远端调用和环境校验脚本

## 安装

把整个仓库内容放到本机 Codex skills 目录下，例如：

```text
%USERPROFILE%\.codex\skills\remote-cluster-workflow
```

然后重启 Codex 让 skill 生效。

## 依赖

这个 skill 依赖 remote profile。profile 默认放在：

```text
%USERPROFILE%\.codex\remote-profiles
```

profile 里通常至少要定义：

- `sshTarget`
- `remoteWorkdir`
- `environment.activate`
- `resource.template`

如果你要创建或修改 profile，先看：

- `references/profile-schema.md`
- `references/example-profiles.md`

如果你目前还只能通过 MobaXterm 密码登录，先看：

- `references/password-bootstrap.md`

## 适用场景

这个 skill 适合：

- “去远端服务器帮我跑测试”
- “ssh 到集群上执行训练”
- “用某个 profile 去 login node 跑命令”
- “帮我检查远端 conda / venv / UV 环境”
- “帮我在集群上分配指定 node 和 cores 跑任务”

这个 skill 不适合：

- 纯本地任务
- 只想看 profile 写法，不需要真实执行
- 依赖 MobaXterm 窗口状态的临时人工操作

## 推荐调用方式

最简单的理解是：只要用户明确要求“去远端跑”，这个 skill 就应该触发。

典型 prompt 例子：

```text
帮我用 ml-gpu03 这个 profile 在远端跑 pytest，只跑 tests/test_model.py，gpu03，8 核。
```

```text
去远端服务器帮我看一下 /data/agent-app 这个 UV 项目能不能启动。
```

```text
帮我在集群上跑 python train.py --epochs 1，先别乱猜资源，缺什么就问我。
```

## 推荐执行顺序

建议按这个顺序使用：

1. 选择匹配的 profile
2. 运行 `test-remote-profile`
3. 如果任务依赖环境，运行 `verify-remote-env`
4. 再用 `invoke-remote-task` 真正执行任务
5. 汇总关键结果给用户

## 常用脚本

- `scripts/test-remote-profile.cmd`
- `scripts/verify-remote-env.cmd`
- `scripts/invoke-remote-task.cmd`

例如先测试 profile：

```powershell
& "%USERPROFILE%\.codex\skills\remote-cluster-workflow\scripts\test-remote-profile.cmd" `
  -Profile "%USERPROFILE%\.codex\remote-profiles\my-profile.json" `
  -Node "gpu03" `
  -Cores 8
```

再执行任务：

```powershell
& "%USERPROFILE%\.codex\skills\remote-cluster-workflow\scripts\invoke-remote-task.cmd" `
  -Profile "%USERPROFILE%\.codex\remote-profiles\my-profile.json" `
  -Command "python -m pytest tests/test_model.py -q" `
  -Node "gpu03" `
  -Cores 8
```

## 测试与评分

仓库里已经包含两份评估辅助文件：

- `test-prompts.json`：用于 dry-run 的典型 prompt 集
- `results.tsv`：记录每轮评估和优化结果

如果后续继续优化这个 skill，建议流程是：

1. 先补或更新 `test-prompts.json`
2. 修改 `SKILL.md`
3. 再把评估结果追加到 `results.tsv`

这样每一轮改动都可追踪。
