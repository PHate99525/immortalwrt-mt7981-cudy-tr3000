[定制教程](https://xiabee.eu.org/customize.html) | [刷写教程](https://xiabee.eu.org/install.html)

<div align=center>
<img src="tr3000.png" height=200px align="center">
</div>

---

## immortalwrt 源码

编译自 https://github.com/padavanonly/immortalwrt-mt798x-6.6 ，兼容 Cudy Tr3000 128M 新 flash

---

## 大分区 ubootmod 固件

本仓库默认编译的 ubootmod 固件为 112M 分区，若你想编译 122M 分区固件，请将 `diy-part2.sh` 中取消以下注释：

```sh
# set ubi to 122M
# sed -i 's/reg = <0x5c0000 0x7000000>;/reg = <0x5c0000 0x7a40000>;/' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts
```

---

## DHCP uboot

编译自 https://github.com/weekdaycare/bl-mt798x-dhcpd 感谢大佬开源，兼容新 flash

![](/uboot.png)

128M uboot 为三分区 uboot 支持原厂 ubi 大小 64MB，扩容 ubi 分区 112MB，最大 ubi 分区 122MB

256M uboot 为单分区 uboot

---

## USB 供电控制

上游的最新源码已经打开了默认供电，具体可以见这条 [commit](https://github.com/padavanonly/immortalwrt-mt798x-6.6/commit/86356f8a2f796e5808fda25ce3e3bf6b3cc3278e)

若你想关闭 USB 供电执行命令

```bash
echo 0 > /sys/class/gpio/modem_power/value
```

恢复供电执行命令

```bash
echo 1 > /sys/class/gpio/modem_power/value
```

---

## 第三方软件包

- [OpenClash](https://github.com/vernesong/OpenClash)
- [Bandix](https://github.com/timsaya/luci-app-bandix)
- [luci-theme-aurora](https://github.com/eamonxg/luci-theme-aurora)
- [luci-app-aurora-config](https://github.com/eamonxg/luci-app-aurora-config)
- luci-app-ttyd
- luci-app-upnp
- kmod-usb-net-cdc-ether
- kmod-usb-net-rndis
- kmod-mtd-rw

---

## MT7612U USB 无线网卡

本项目使用的厂商源码分支没有标准的 `package/kernel/mt76`，所以原先在
`make menuconfig` 中找不到 `kmod-mt76x2u`，与 Linux 6.6 是否支持芯片无关。

`diy-part1.sh` 会在更新 feeds 前执行 `scripts/add-mt76.sh`，从 ImmortalWrt
24.10 固定提交 `2e13223aaa378a2cfcd01b9739aef6fa3cc645e1` 导入完整的 mt76
软件包定义及兼容补丁。SSH 菜单配置和正式编译均使用该步骤；若源码已经带有
`package/kernel/mt76`，脚本会停止，需先确认应使用哪个版本，避免覆盖源码自带的驱动。

三个机型配置均已启用以下软件包，保留内置无线使用的 `kmod-mt_wifi` 和现有的
`wpad-openssl`。mt76 的其他依赖及 MT7662U 固件由软件包规则自动安装：

```text
CONFIG_PACKAGE_kmod-cfg80211=y
CONFIG_PACKAGE_kmod-mac80211=y
CONFIG_PACKAGE_kmod-mt76x2u=y
CONFIG_PACKAGE_usb-modeswitch=y
```

将这些修改推送到自己的 GitHub 仓库后，运行 `ImmortalWrt Builder`，选择对应机型
或 `all` 即可，通常无需勾选 SSH。编译会检查 `make defconfig` 后驱动是否仍被选中，
缺失时直接报错；成功后从该次运行的 Artifacts 或启用发布后的 Release 下载对应
`sysupgrade.bin`。这里的 `=y` 表示将驱动软件包装入固件，驱动仍以 `.ko` 模块加载。

若要在 SSH 中调整配置，选项位于 `Kernel modules -> Wireless Drivers -> kmod-mt76x2u`，
也可在菜单中按 `/` 搜索 `mt76x2u`；保持为 `<*>`。菜单保存后，后续编译会检出保存配置
后的项目提交。首次 Actions 编译和实机验证仍是确认该厂商分支兼容性的必要步骤。

刷入固件并将网卡切换为 `0e8d:7612` 后检查：

```sh
lsmod | grep mt76
dmesg | grep -iE 'mt76|firmware|usb'
iw phy
wifi config
uci show wireless
```

在 LuCI 中配置新增的 `mac80211` 无线设备，不要改动内置无线的 `mtwifi` 设备。
固件已包含 `usb-modeswitch`，但特定设备从 `0e8d:2870` 自动切换的规则仍需实机确认；
若重启后仍显示该 ID，沿用已验证的切换方式。

---

## SSH 连接 Action

可以通过 ssh 连接到 Action 工作流来配置 `menuconfig` 。

手动运行 `ImmortalWrt Builder`，选择单个设备（不能选 `all`），并勾选 SSH 选项。
工作流使用 Upterm 公共中继提供 SSH 会话，仅允许使用触发者 GitHub 账号上的 SSH 公钥连接。
在 `SSH connection to Menuconfig` 步骤的日志中找到 SSH 连接命令；连接后执行：

```sh
cd /workdir/openwrt
make menuconfig
# 保存并退出 menuconfig 后，通知工作流继续推送配置和编译：
touch "$GITHUB_WORKSPACE/continue"
```

SSH 步骤最多运行 15 分钟，请在超时前保存配置并创建 `continue` 文件；直接取消运行或超时会跳过配置推送。
如果不显示连接命令，可在 GitHub 的 Re-run jobs 中勾选 Enable debug logging，
检查 Upterm 启动日志及到 `uptermd.upterm.dev` 的连接情况。

---

## 编译注意事项

GitHub Actions 存储有限，大型软件包（如 sing-box 或 alist）建议使用预编译方式，而不是源码编译，即在编译过程中加入已经编译好现成软件包。否则你应该会碰到超长编译时间 + 超出 Action 储存。示例：

```sh
# 创建存储二进制文件的目录
BIN_DIR="$GITHUB_WORKSPACE/openwrt/files/usr/bin"
mkdir -p "$BIN_DIR"

# -------- 下载并解压 xray-core ARM64 -------
echo "Downloading xray-core..."
curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/download/v25.10.15/Xray-linux-arm64-v8a.zip
unzip -o xray.zip -d "$BIN_DIR"
chmod +x "$BIN_DIR/xray"
rm xray.zip

# -------- 下载并解压 sing-box ARM64 -------
echo "Downloading sing-box..."
curl -L -o sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.12.12/sing-box-1.12.12-linux-arm64.tar.gz
TMP_DIR=$(mktemp -d)
tar -xzf sing-box.tar.gz -C "$TMP_DIR"
mv "$TMP_DIR"/sing-box-1.12.12-linux-arm64/sing-box "$BIN_DIR"/sing-box
chmod +x "$BIN_DIR/sing-box"
rm -rf "$TMP_DIR"
rm sing-box.tar.gz
```

---

## Credits

- [bl-mt798x-dhcpd](https://github.com/weekdaycare/bl-mt798x-dhcpd)
- [bl-mt798x](https://github.com/hanwckf/bl-mt798x)
- [immortalwrtwrt](https://github.com/padavanonly/immortalwrt-mt798x-6.6)
- [P3TERX](https://github.com/P3TERX)
- [Microsoft Azure](https://azure.microsoft.com)
- [GitHub Actions](https://github.com/features/actions)
- [OpenWrt](https://github.com/openwrt/openwrt)
- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
- [Mikubill/transfer](https://github.com/Mikubill/transfer)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
- [Mattraks/delete-workflow-runs](https://github.com/Mattraks/delete-workflow-runs)
- [dev-drprasad/delete-older-releases](https://github.com/dev-drprasad/delete-older-releases)
- [peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)

---

## License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/main/LICENSE) © [**P3TERX**](https://p3terx.com)
