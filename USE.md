我梳理了项目的命令入口。仓库提供 Nix flake 目标和四个 Rust workspace crate；其中 `vjcommon` 是库，不是命令行程序。项目没有 README；要查看完整的动态 package 列表，可以运行 `nix flake show`。

**构建、开发与检查**

```sh
nix flake show
nix flake check
nix fmt
nix develop .#vjenv
nix develop .#vjproj
nix develop .#vjvr
nix develop .#vjcommon

cargo build --workspace
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
cargo fmt --check
statix check .
```

此 flake 的目标系统是 `x86_64-linux`，声明的 NixOS 主机为 `main` 和 `mini`：

```sh
nix build .#nixosConfigurations.main.config.system.build.toplevel
nix build .#nixosConfigurations.mini.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#main
sudo nixos-rebuild switch --flake .#mini
```

`nix flake check` 会运行仓库定义的检查，包括 Rust 测试与 lint、Nix 格式与 lint、主机安全检查，以及功能行为检查。`nix fmt` 和 `statix fix .` 会修改文件。

**项目工具**

```sh
nix run .#regen
nix run .#config-diff -- REF_A REF_B [--hosts main,mini] [--closure]

nix run .#config-diff -- \
  "git+file:///home/t/nixconf?rev=$(git rev-parse HEAD)" \
  . \
  --hosts main,mini
```

`regen` 会重新生成仓库中的生成文件。`config-diff` 用于比较两个 flake 引用的主机配置快照；`--closure` 还会构建并比较它们的闭包。定义见 `checks.nix` 和 `config-diff.nix`。

**Rust 命令行工具**
可以通过 `nix run .#vjenv -- ...`、`nix run .#vjproj -- ...` 或 `nix run .#vjvr -- ...` 运行工具。每个工具都支持 `--help`。

- `vjenv`：`status`、`env [SHELL] [--no-devshell]`、`assign [--identity NAME]`、`use IDENTITY [--shell SHELL]`、`use --clear`、`exec CMD...`、`shells`、`allow [DEVSHELL]`、`deny`、`reload`、`gc [--dry-run]`、`shellinit [SHELL]`、`completions SHELL`。另有全局选项 `--cwd DIR`。详见 vjenv CLI。
- `vjproj`：工作区操作包括 `view`、`tag`、`toggle-view`、`toggle-tag`、`left`、`right`、`move-left`、`move-right`、`switch`、`send`、`next`、`focus`、`fresh`、`dir`、`status`、`watch`、`serve`、`url`、`reset`；agent 操作包括 `agent report`、`agent notify`、`agent end`；项目操作包括 `project list`、`assign`、`describe`、`clear`、`swap`、`forget`。详见 vjproj CLI。
- `vjvr`：`serve`、`status`、`watch`、`request JSON`、`probe`。详见 vjvr CLI。
- `vjmusic`：`liked`。这是单独的 Nix package，不属于 Cargo crate。

Nix wrapper 模块还定义了 `neovim`、`mangowc`、`fish`、`git`、`tmux`、`kitty`、`codex`、`opencode` 等程序；具体哪些程序可用取决于主机和 profile。完整 flake package 列表可通过 `nix flake show` 查看；wrapper 输出的定义见 `wrappers.nix`。

---

## Steam Deck LiveCD 安装

从 NixOS LiveCD 启动并联网。安装会清空 `/dev/nvme0n1` 上的全部数据；先用 `lsblk` 确认这是 Steam Deck 的目标盘。

```sh
read -r -p "Git 仓库 URL: " REPO_URL
nix --extra-experimental-features 'nix-command flakes' \
  shell nixpkgs#git --command git clone "$REPO_URL" "$HOME/nixconf"
cd "$HOME/nixconf"

lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS
```

确认设备后，运行 Disko。它会按 `deck` 配置分区、格式化并挂载磁盘：

```sh
sudo nix --experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- \
  --mode disko --flake .#deck
```

项目用户 `t` 的密码 hash 存放在 `/persist/passwd`。先生成 hash 并写入已挂载的持久化分区：

```sh
PASSWORD_HASH="$(
  nix --experimental-features 'nix-command flakes' \
    shell nixpkgs#mkpasswd --command mkpasswd --method=sha-512
)"
sudo install -m 0600 /dev/null /mnt/persist/passwd
printf '%s\n' "$PASSWORD_HASH" | sudo tee /mnt/persist/passwd >/dev/null
unset PASSWORD_HASH
```

把配置仓库放到系统持久化的 `nixos` 位置，方便安装后管理：

```sh
sudo install -d -m 0755 /mnt/persist/system/etc/nixos
sudo cp -a ./. /mnt/persist/system/etc/nixos/
```

安装 `deck` 主机配置。安装程序会提示设置 root 密码；这和前面设置的 `t` 用户密码是分开的：

```sh
sudo nixos-install \
  --root /mnt \
  --flake .#deck \
  --option accept-flake-config true \
  --option experimental-features 'nix-command flakes' \
  --option extra-substituters 'https://nyx-cache.chaotic.cx/' \
  --option extra-trusted-public-keys \
    'nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk='

sync
sudo reboot
```

注意：本仓库的 flake 主机名是 `deck`，不是 `.origin` 配置中的 `steamdeck`。Disko 配置会清除目标盘上的现有分区和数据。

Disko 的 `--flake .#deck` 用法对应官方的 flake 集成；这里不能传 `disko.nix` 作为独立 Disko 配置，因为它是本项目封装的 `diskoConfigurations.deck` 定义。
