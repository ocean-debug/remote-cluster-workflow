# remote-cluster-workflow

`remote-cluster-workflow` 是一个给 Codex 用的 skill，用来把任务稳定地执行到用户自管的远端 Linux 服务器或 HPC 集群上，而不是只在本机运行。

它重点解决这几件事：

- 复用本地 OpenSSH 凭据连接远端
- 通过 profile 固定远端工作目录、环境激活方式和资源模板
- 在 login node、直连主机、Slurm `srun` 等场景下运行命令
- 在真正执行前先做 profile 校验和环境验证

## 适用场景

适合下面这类请求：

- “去远端服务器帮我跑测试”
- “ssh 到集群上执行训练”
- “用某个 profile 到 login node 跑命令”
- “检查远端 conda / venv / UV 环境是否正常”

不适合纯本地任务，或者只想看文档示例、不需要真实远端执行的场景。

## 安装

把整个目录放到你的 Codex skills 目录下：

```text
%USERPROFILE%\.codex\skills\remote-cluster-workflow
```

至少需要这些文件：

```text
remote-cluster-workflow/
  SKILL.md
  README.md
  test-prompts.json
  results.tsv
  references/
  scripts/
```

如果你是从 GitHub 安装，可以直接把仓库内容放到上面的目录里，然后重启 Codex 让新 skill 生效。

## 远端 Profile

这个 skill 依赖 remote profile。profile 默认放在：

```text
%USERPROFILE%\.codex\remote-profiles
```

profile 里通常会定义：

- `sshTarget`
- `remoteWorkdir`
- `environment.activate`
- `resource.template`

如果你要新建或修改 profile，先看：

- `references/profile-schema.md`
- `references/example-profiles.md`

如果你现在还只能通过 MobaXterm 密码登录，先看：

- `references/password-bootstrap.md`

## 调用方式

最简单的理解是：用户只要明确说“去远端跑”，这个 skill 就应该被触发。

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

这个 skill 的推荐路径是：

1. 选一个匹配的 profile
2. 跑 `test-remote-profile`
3. 如果任务依赖环境，跑 `verify-remote-env`
4. 再用 `invoke-remote-task` 真正执行命令
5. 汇总结果给用户

## 脚本入口

常用脚本有这几个：

- `scripts/test-remote-profile.cmd`
- `scripts/verify-remote-env.cmd`
- `scripts/invoke-remote-task.cmd`

例如先测 profile：

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

这个仓库带了两份评估辅助文件：

- `test-prompts.json`：典型 dry-run 测试 prompt
- `results.tsv`：每轮评估和优化记录

如果你要继续优化这个 skill，建议先补测试 prompt，再更新 `results.tsv`，保持每一轮修改都可追踪。
