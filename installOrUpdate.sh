#!/bin/sh
#
# Written by EungShik Kim on 2023.02.16
# Updated by EungShik Kim on 2025.03.29
#
SCRIPT_PATH=$(dirname $0)
##### Functions
function writeCustomCSS() {
    echo "/* Override src/css/common.css here by uncomment followings or copy code from src/css/common.css */" > $CUSTOM_CSS
    echo "/*" >> $CUSTOM_CSS
    echo ".login_area .btn_login {display:block;width:384px;height:60px;margin:14px auto 0 auto;text-align:center;font-size:20px;line-height:60px;color:#fff;box-shadow:0 2px 2px rgba(0, 0, 0, 0.24), 0 0 2px;border-radius:4px;background:#2CBBB6;}" >> $CUSTOM_CSS
    echo ".qa_type2 .header {height:80px;background-color:#2CBBB6;}" >> $CUSTOM_CSS
    echo ".sub_type2 .header {background-color:#2CBBB6;}" >> $CUSTOM_CSS
    echo ".sub_type2 .header .search_area .inp_self {background:#2CBBB6;}"  >> $CUSTOM_CSS
    echo "*/" >> $CUSTOM_CSS
}
##### Change current directory
cd $SCRIPT_PATH

if [ ! -d src ]; then
    git submodule add -f https://github.com/neoroman/JenkinsAppDistTemplateSource.git src
    git config -f .gitmodules submodule.src.url https://github.com/neoroman/JenkinsAppDistTemplateSource.git
    git submodule sync
    git submodule update --force --recursive --init --remote 
    git submodule foreach git pull origin main
else
    git submodule sync
    git submodule update --force --recursive --init --remote 
    git submodule foreach git pull origin main
fi
#####
# Check if src/update.sh exists
if [ -f src/update.sh ]; then
    # Execute the update script
    echo "Executing src/update.sh..."
    # Make symbolic links for src/update.sh to this script after renaming 'installOrUpdate.sh' to 'na_installOrUpdate.sh'
    if [ -f installOrUpdate.sh ]; then
        mv installOrUpdate.sh na_installOrUpdate.sh
    fi
    # Create symbolic link to src/update.sh to installOrUpdate.sh
    ln -sf src/update.sh installOrUpdate.sh
    # Execute the symbolic linked script
    ./installOrUpdate.sh
else
    echo "src/update.sh not found. Skipping update."
fi


##### Make Directories
for dir in config lang custom images ios_distributions android_distributions; do
    [ ! -d "$dir" ] && mkdir "$dir"
done

# Set permissions for distribution directories
chmod 777 ios_distributions android_distributions

# Create symbolic links if not exist
if [ ! -h lang/default.json ] && [ ! -f lang/default.json ]; then
    ln -s ../src/lang/default.json lang/default.json
fi

if [ ! -h images/HomeIcon.png ]; then
    ln -s ../src/images/HomeIcon.png images/HomeIcon.png
fi

# Create custom CSS if not exists
CUSTOM_CSS="custom/user.css"
if [ ! -f $CUSTOM_CSS ]; then
    writeCustomCSS
fi

##### Remove Symbolic Links and Directories if exists
# Directories to clean
declare -a dirs_to_clean=(
    "android" "ios" "css" "dist" "font" "images/svg" 
    "js" "plugin" "shells" "utils" "phpmodules" ".test"
)

# Files to clean
declare -a files_to_clean=(
    "common.php" "config.php" "dist_client.php" "dist_domestic.php" "distributions.php"
    "doDistributions.sh" "feedback.php" "index.html" "login.php" "logout.php" 
    "setup.php" "pw_guide.php" "pw_guide_uaqa.php" "pw_guide.html" "pw_guide_uaqa.html" 
    "recommand.php" "remove_html_snippet.php" "sendmail_gmail.php" "sendmail_gmail_release.php" 
    "sendmail_gmail_uDev3.php" "syncToNasNeo2UA.sh" "test.php" "undo_remove_html_snippet.php" 
    "makeJsonFromHTML.sh" "reorderFileTime.sh" "sendmail_domestic.php" "sendmail_release.php" 
    "sshFunctions.sh" "upload.php" "upload_ok.php"
)

# Clean directories
for dir in "${dirs_to_clean[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
    elif [ -h "$dir" ]; then
        rm -f "$dir"
    fi
done

# Clean files
for file in "${files_to_clean[@]}"; do
    if [ -f "$file" ] || [ -h "$file" ]; then
        rm -f "$file"
    fi
done

# Special case for wildcard pattern
if [ -f sendmail_u*.php ]; then
    rm -f sendmail_u*.php
fi

# Set locale if not defined
if test -z $LC_ALL; then
    export LC_ALL="C"
fi
#####
if [ ! -d src ]; then
    git submodule add -f https://github.com/neoroman/JenkinsAppDistTemplateSource.git src
    git config -f .gitmodules submodule.src.url https://github.com/neoroman/JenkinsAppDistTemplateSource.git
    git submodule sync
    git submodule update --force --recursive --init --remote 
    git submodule foreach git pull origin main
else
    git submodule sync
    git submodule update --force --recursive --init --remote 
    git submodule foreach git pull origin main
fi
#####


# Create symbolic links to mimic Apache rewrite rules for non-Apache servers
echo "Creating symbolic links for non-Apache servers..."
ln -sf src/config.php config.php
ln -sf src/dist_domestic.php dist_domestic.php
ln -sf src/dist_client.php dist_client.php
ln -sf src/phpmodules phpmodules
ln -sf src/android android
ln -sf src/ios ios
ln -sf src/css css
ln -sf src/font font
ln -sf src/js js
ln -sf src/plugin plugin
ln -sf src/shells shells
ln -sf src/index.html index.html
ln -sf src/login.php login.php
ln -sf src/logout.php logout.php
ln -sf src/setup.php setup.php

# 원본 디렉토리와 대상 디렉토리의 절대 경로 계산
SRC_SVG_PATH="$(pwd)/src/images/svg"
TARGET_SVG_PATH="$(pwd)/images/svg"

# 대상 디렉토리의 존재 여부 확인 및 필요시 제거
if [ -e "$TARGET_SVG_PATH" ] || [ -h "$TARGET_SVG_PATH" ]; then
    rm -rf "$TARGET_SVG_PATH"
fi

# 절대 경로를 사용하여 심볼릭 링크 생성
ln -sf "$SRC_SVG_PATH" "$TARGET_SVG_PATH"
echo "Created symbolic link: $TARGET_SVG_PATH -> $SRC_SVG_PATH"

# Additional redirects for specific HTML files - Create HTML redirects instead of symlinks
echo "Creating HTML redirects for specific pages..."

# Create dist_client.html with redirect if it doesn't exist or update it
if [ -h dist_client.html ]; then
    # If it's a symbolic link, remove it first
    rm -f dist_client.html
    echo "Removed symbolic link dist_client.html"
fi

if [ ! -f dist_client.html ] || ! grep -q "dist_client.php" dist_client.html; then
    cat > dist_client.html << 'EOL'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<META http-equiv='REFRESH' content='0;url=dist_client.php'>
</HEAD>
</HTML>
EOL
    echo "Created/Updated dist_client.html with redirect to dist_client.php"
else
    echo "dist_client.html already exists with correct redirect"
fi

# Create dist_uaqa.html with redirect if it doesn't exist or update it
if [ -h dist_uaqa.html ]; then
    # If it's a symbolic link, remove it first
    rm -f dist_uaqa.html
    echo "Removed symbolic link dist_uaqa.html"
fi

if [ ! -f dist_uaqa.html ] || ! grep -q "dist_domestic.php" dist_uaqa.html; then
    cat > dist_uaqa.html << 'EOL'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<META http-equiv='REFRESH' content='0;url=dist_domestic.php'>
</HEAD>
</HTML>
EOL
    echo "Created/Updated dist_uaqa.html with redirect to dist_domestic.php"
else
    echo "dist_uaqa.html already exists with correct redirect"
fi

# Create symbolic link for dist_kt.html if needed
if [ ! -h dist_kt.html ] || [ "$(readlink dist_kt.html)" != "dist_client.html" ]; then
    rm -f dist_kt.html
    ln -sf dist_client.html dist_kt.html
    echo "Created symbolic link: dist_kt.html -> dist_client.html"
else
    echo "dist_kt.html symbolic link already exists"
fi

chmod -R 777 $SCRIPT_PATH
