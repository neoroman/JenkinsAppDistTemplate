#!/bin/sh
#
# Written by EungShik Kim on 2023.02.16
#
##### Make Directories
if [ ! -d config ]; then
    mkdir config
fi
if [ ! -d lang ]; then
    mkdir lang
fi
if [ ! -d images ]; then
    mkdir images
else
    rm -rf images
    mkdir images
fi
# if [ ! -d langcache ]; then
#     mkdir langcache
# fi
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
if [ ! -h android ]; then
    echo ' ' #ln -s src/android
else
    rm -f android
fi
if [ -d ios ]; then
    rm -rf ios
fi
if [ ! -h ios ]; then
    echo ' ' # ln -s src/ios
else
    rm -f ios
fi
if [ -d css ]; then
    rm -rf css
fi
if [ ! -h css ]; then
    echo ' ' # ln -s src/css
else
    rm -f css
fi
if [ -d dist ]; then
    rm -rf dist
fi
if [ -d font ]; then
    rm -rf font
fi
if [ ! -h font ]; then
    echo ' ' # ln -s src/font
else
    rm -f font
fi
if [ -d images/svg ]; then
    rm -rf images/svg
fi
if [ ! -h images/svg ]; then
    echo ' ' # ln -s ../src/images/svg images/svg
else
    rm -f images/svg
fi
if [ -d js ]; then
    rm -rf js
fi
if [ ! -h js ]; then
    echo ' ' # ln -s src/js
else
    rm -f js
fi
if [ ! -h phpmodules ]; then
    echo ' ' # ln -s src/phpmodules
else
    rm -f phpmodules
fi
if [ -d plugin ]; then
    rm -rf plugin
fi
if [ ! -h plugin ]; then
    echo ' ' # ln -s src/plugin
else
    rm -f plugin
fi
if [ -d shells ]; then
    rm -rf shells
fi
if [ ! -h shells ]; then
    echo ' ' # ln -s src/shells
else
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
if [ ! -h config.php ]; then
    echo ' ' # ln -s src/config.php
else
    rm -f config.php
fi
if [ -f dist_client.php ]; then
    rm -f dist_client.php
fi
if [ ! -h dist_client.php ]; then
    echo ' ' # ln -s src/dist_client.php
else
    rm -f dist_client.php
fi
if [ -f dist_domestic.php ]; then
    rm -f dist_domestic.php
fi
if [ ! -h dist_domestic.php ]; then
    echo ' ' # ln -s src/dist_domestic.php
else
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
if [ ! -h index.html ]; then
    echo ' ' # ln -s src/index.html
else
    rm -f index.html
fi
if [ -f login.php ]; then
    rm -f login.php
fi
if [ ! -h login.php ]; then
    echo ' ' # ln -s src/login.php
else
    rm -f login.php
fi
if [ -f logout.php ]; then
    rm -f logout.php
fi
if [ ! -h logout.php ]; then
    echo ' ' # ln -s src/logout.php
else
    rm -f logout.php
fi
if [ -d phpmodules ]; then
    rm -rf phpmodules
fi
if [ -f setup.php ]; then
    rm -f setup.php
fi
if [ ! -h setup.php ]; then
    echo ' ' # ln -s src/setup.php
else
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
chmod 777 src/langcache
