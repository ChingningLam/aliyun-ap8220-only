#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	echo " "

	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#修改argon主题字体和颜色
if [ -d *"luci-theme-argon"* ]; then
	echo " " && cd ./luci-theme-argon/

	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon

	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

#修改aurora菜单式样
if [ -d *"luci-app-aurora-config"* ]; then
	echo " " && cd ./luci-app-aurora-config/

	sed -i "s/nav_type '.*'/nav_type 'dropdown'/g" $(find ./root/usr/share/aurora/ -type f -name "*.template")

	cd $PKG_PATH && echo "theme-aurora has been fixed!"
fi

#修改mini-diskmanager菜单位置
if [ -d *"luci-app-mini-diskmanager"* ]; then
	echo " " && cd ./luci-app-mini-diskmanager/

	sed -i "s/services/system/g" ./luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json

	cd $PKG_PATH && echo "mini-diskmanager has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "

	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi

# 预置 OpenClash Mihomo (Clash Meta) 内核
if [ -d *"luci-app-openclash"* ]; then
	echo " "
	echo "Start downloading OpenClash Mihomo (Clash Meta) kernel..."
	OC_CORE_PATH="luci-app-openclash/root/etc/openclash/core"
	mkdir -p "$OC_CORE_PATH"
	# 根据 WRT_TARGET 选择对应架构
	# 默认使用 arm64 架构，x86 平台使用 amd64
	ARCH="arm64"
	if [[ "${WRT_TARGET,,}" == *"x86"* ]]; then
		ARCH="amd64"
	fi
	echo "Target platform: $WRT_TARGET, architecture: $ARCH"
	# 获取最新版 Mihomo/Clash Meta 内核版本号
	TAG_NAME=$(curl -sL "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" | jq -r ".tag_name" 2>/dev/null)
	
	# 如果获取失败或为空，则使用默认稳定版本 v1.19.2
	if [ -z "$TAG_NAME" ] || [ "$TAG_NAME" = "null" ]; then
		TAG_NAME="v1.19.2"
		echo "Failed to fetch latest tag name via API, falling back to default: $TAG_NAME"
	else
		echo "Fetched latest Mihomo version: $TAG_NAME"
	fi
	# 下载并解压内核
	# MetaCubeX 发布的文件名为: mihomo-linux-amd64-v1.19.2.gz 或 mihomo-linux-arm64-v1.19.2.gz
	FILE_NAME="mihomo-linux-${ARCH}-${TAG_NAME}"
	DOWNLOAD_URL="https://github.com/MetaCubeX/mihomo/releases/download/${TAG_NAME}/${FILE_NAME}.gz"
	echo "Downloading kernel from: $DOWNLOAD_URL"
	curl -sL -m 300 --retry 3 "$DOWNLOAD_URL" -o "$OC_CORE_PATH/clash_meta.gz"
	
	if [ -f "$OC_CORE_PATH/clash_meta.gz" ]; then
		# 使用 gzip 解压（解压后文件会自动命名为 clash_meta）
		gzip -d -f "$OC_CORE_PATH/clash_meta.gz"
		chmod +x "$OC_CORE_PATH/clash_meta"
		echo "OpenClash Mihomo kernel downloaded and configured successfully!"
	else
		echo "Error: Failed to download OpenClash Mihomo kernel!"
	fi
	cd $PKG_PATH
fi
