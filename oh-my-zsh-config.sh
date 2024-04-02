#!/bin/bash

# 更新软件包列表并安装必要软件
sudo apt update
sudo apt install -y zsh git

# 将 Zsh 设置为默认的 shell
sudo chsh -s "$(which zsh)"

# 安装 Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh is already installed."
fi

# 定义常用变量
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGINS_DIR="${ZSH_CUSTOM}/plugins"
ZSHRC="$HOME/.zshrc"

# 检查.zshrc文件是否存在并更新主题
if [ -f "$ZSHRC" ]; then
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="aussiegeek"/' "$ZSHRC"
    echo "ZSH_THEME has been updated to 'aussiegeek'."
else
    echo ".zshrc file does not exist."
fi

# 安装插件函数
install_plugin() {
    local url=$1
    local plugin=$2
    local plugin_dir="${PLUGINS_DIR}/${plugin}"
    
    if [ ! -d "$plugin_dir" ]; then
        git clone "$url" "$plugin_dir"
    else
        echo "${plugin} already installed."
    fi


     # 检查插件是否已在列表中
    if ! grep -q "plugins=(.*$plugin.*)" "$ZSHRC"; then
        # 使用sed在plugins=()行内添加插件，确保格式正确
        sed -i "/^plugins=(/s/)/ $plugin)/" "$ZSHRC"
        echo "$plugin added to plugins list."
    else
        echo "$plugin already in plugins list."
    fi
}

# 安装插件
install_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git zsh-syntax-highlighting
install_plugin https://github.com/zsh-users/zsh-autosuggestions zsh-autosuggestions
install_plugin https://github.com/zsh-users/zsh-completions zsh-completions

# 添加 zsh-completions fpath 到 .zshrc
FPATH_LINE="fpath+=${ZSH_CUSTOM}/plugins/zsh-completions/src"
if ! grep -Fxq "$FPATH_LINE" "$ZSHRC"; then
    echo "$FPATH_LINE" >> "$ZSHRC"
    echo "Added fpath for zsh-completions to .zshrc."
else
    echo "The fpath for zsh-completions is already added to .zshrc."
fi

sudo source ~/.zshrc
