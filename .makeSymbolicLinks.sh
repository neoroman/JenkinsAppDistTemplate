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

##### Make Symbolic Links
if [ ! -h android ]; then
    if [ -d android ]; then
        rm -rf android
    fi
    ln -s src/android
# else
    #rm -f android
fi
if [ ! -h ios ]; then
    if [ -d ios ]; then
        rm -rf ios
    fi
    ln -s src/ios
# else
    #rm -f ios
fi
if [ ! -h images/svg ]; then
    if [ -d images/svg ]; then
        rm -rf images/svg
    fi
    ln -s ../src/images/svg images/svg
# else
    #rm -f images/svg
fi
if [ ! -h css ]; then
    if [ -d css ]; then
        rm -rf css
    fi
    ln -s src/css
# else
    #rm -f css
fi
if [ ! -h font ]; then
    if [ -d font ]; then
        rm -rf font
    fi
    ln -s src/font
# else
    #rm -f font
fi
if [ ! -h config.php ]; then
    if [ -f config.php ]; then
        rm -f config.php
    fi
    ln -s src/config.php
# else
    #rm -f config.php
fi
if [ ! -h dist_client.php ]; then
    if [ -f dist_client.php ]; then
        rm -f dist_client.php
    fi
    ln -s src/dist_client.php
# else
    #rm -f dist_client.php
fi
if [ ! -h dist_domestic.php ]; then
    if [ -f dist_domestic.php ]; then
        rm -f dist_domestic.php
    fi
    ln -s src/dist_domestic.php
# else
    #rm -f dist_domestic.php
fi
if [ ! -h index.html ]; then
    if [ -f index.html ]; then
        rm -f index.html
    fi
    ln -s src/index.html
# else
    #rm -f index.html
fi
if [ ! -h js ]; then
    if [ -d js ]; then
        rm -rf js
    fi
    ln -s src/js
# else
    #rm -f js
fi
if [ ! -h login.php ]; then
    if [ -f login.php ]; then
        rm -f login.php
    fi
    ln -s src/login.php
# else
    #rm -f login.php
fi
if [ ! -h logout.php ]; then
    if [ -f logout.php ]; then
        rm -f logout.php
    fi
    ln -s src/logout.php
# else
    #rm -f logout.php
fi
if [ ! -h phpmodules ]; then
    if [ -d phpmodules ]; then
        rm -rf phpmodules
    fi
    ln -s src/phpmodules
# else
    #rm -f phpmodules
fi
if [ ! -h plugin ]; then
    if [ -d plugin ]; then
        rm -rf plugin
    fi
    ln -s src/plugin
# else
    #rm -f plugin
fi
if [ ! -h shells ]; then
    if [ -d shells ]; then
        rm -rf shells
    fi
    ln -s src/shells
# else
    #rm -f shells 
fi
if [ ! -h setup.php ]; then
    if [ -f setup.php ]; then
        rm -f setup.php
    fi
    ln -s src/setup.php
# else
    #rm -f setup.php
fi
if test -z $LC_ALL; then
    export LC_ALL="C"
fi
#####
if [ ! -d src ]; then
    git submodule add https://github.com/neoroman/JenkinsAppDistTemplateSource.git src
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
