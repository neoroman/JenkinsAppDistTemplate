#!/bin/sh
#
# Written by EungShik Kim on 2023.02.16
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
##### Make Directories
if [ ! -d config ]; then
    mkdir config
fi
if [ ! -d lang ]; then
    mkdir lang
fi
if [ ! -h lang/default.json ]; then
    if [ ! -f lang/default.json ]; then
        ln -s ../src/lang/default.json lang/default.json
    fi
fi
CUSTOM_CSS="custom/user.css"
if [ ! -d custom ]; then
    mkdir custom
    writeCustomCSS
elif [ ! -f $CUSTOM_CSS ]; then
    writeCustomCSS
fi
if [ ! -d images ]; then
    mkdir images
fi
if [ ! -h images/HomeIcon.png ]; then
    ln -s ../src/images/HomeIcon.png images/HomeIcon.png
fi
if [ ! -d ios_distributions ]; then
    mkdir ios_distributions
fi
chmod 777 ios_distributions
if [ ! -d android_distributions ]; then
    mkdir android_distributions
fi
chmod 777 android_distributions
##### Copy defaults files from src

##### Remove Symbolic Links if exists
if [ -d android ]; then
    rm -rf android
fi
if [ -h android ]; then
    rm -f android
fi
if [ -d ios ]; then
    rm -rf ios
fi
if [ -h ios ]; then
    rm -f ios
fi
if [ -d css ]; then
    rm -rf css
fi
if [ -d dist ]; then
    rm -rf dist
fi
if [ -d font ]; then
    rm -rf font
fi
if [ -h font ]; then
    rm -f font
fi
if [ -d images/svg ]; then
    rm -rf images/svg
fi
if [ -h images/svg ]; then
    rm -f images/svg
fi
if [ -d js ]; then
    rm -rf js
fi
if [ -h js ]; then
    rm -f js
fi
if [ -h phpmodules ]; then
    rm -f phpmodules
fi
if [ -d plugin ]; then
    rm -rf plugin
fi
if [ -h plugin ]; then
    rm -f plugin
fi
if [ -d shells ]; then
    rm -rf shells
fi
if [ -h shells ]; then
    rm -f shells 
fi
if [ -d utils ]; then
    rm -rf utils
fi
if [ -f common.php ]; then
    rm -f common.php
fi
if [ -f config.php ]; then
    rm -f config.php
fi
if [ -h config.php ]; then
    rm -f config.php
fi
if [ -f dist_client.php ]; then
    rm -f dist_client.php
fi
if [ -h dist_client.php ]; then
    rm -f dist_client.php
fi
if [ -f dist_domestic.php ]; then
    rm -f dist_domestic.php
fi
if [ -h dist_domestic.php ]; then
    rm -f dist_domestic.php
fi
if [ -f distributions.php ]; then
    rm -f distributions.php
fi
if [ -f doDistributions.sh ]; then
    rm -f doDistributions.sh
fi
if [ -f feedback.php ]; then
    rm -f feedback.php
fi
if [ -f index.html ]; then
    rm -f index.html
fi
if [ -h index.html ]; then
    rm -f index.html
fi
if [ -f login.php ]; then
    rm -f login.php
fi
if [ -h login.php ]; then
    rm -f login.php
fi
if [ -f logout.php ]; then
    rm -f logout.php
fi
if [ -h logout.php ]; then
    rm -f logout.php
fi
if [ -d phpmodules ]; then
    rm -rf phpmodules
fi
if [ -f setup.php ]; then
    rm -f setup.php
fi
if [ -h setup.php ]; then
    rm -f setup.php
fi
if [ -f pw_guide.php ]; then
    rm -f pw_guide.php
fi
if [ -f pw_guide_uaqa.php ]; then
    rm -f pw_guide_uaqa.php
fi
if [ -f pw_guide.html ]; then
    rm -f pw_guide.html
fi
if [ -f pw_guide_uaqa.html ]; then
    rm -f pw_guide_uaqa.html
fi
if [ -f recommand.php ]; then
    rm -f recommand.php
fi
if [ -f remove_html_snippet.php ]; then
    rm -f remove_html_snippet.php
fi
if [ -f sendmail_gmail.php ]; then
    rm -f sendmail_gmail.php
fi
if [ -f sendmail_gmail_release.php ]; then
    rm -f sendmail_gmail_release.php
fi
if [ -f sendmail_gmail_uDev3.php ]; then
    rm -f sendmail_gmail_uDev3.php
fi
if [ -f sendmail_u*.php ]; then
    rm -f sendmail_u*.php
fi
if [ -f syncToNasNeo2UA.sh ]; then
    rm -f syncToNasNeo2UA.sh
fi
if [ -f syncToNasNeo2UA.sh ]; then
    rm -f syncToNasNeo2UA.sh
fi
if [ -f test.php ]; then
    rm -f test.php
fi
if [ -f undo_remove_html_snippet.php ]; then
    rm -f undo_remove_html_snippet.php
fi
if [ -f makeJsonFromHTML.sh ]; then
    rm -f makeJsonFromHTML.sh
fi
if [ -f reorderFileTime.sh ]; then
    rm -f reorderFileTime.sh
fi
if [ -f sendmail_domestic.php ]; then
    rm -f sendmail_domestic.php
fi
if [ -f sendmail_release.php ]; then
    rm -f sendmail_release.php
fi
if [ -f sshFunctions.sh ]; then
    rm -f sshFunctions.sh
fi
if [ -f upload.php ]; then
    rm -f upload.php
fi
if [ -f upload_ok.php ]; then
    rm -f upload_ok.php
fi
if [ -d .test ]; then
    rm -rf .test
fi
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
chmod -R 777 .
