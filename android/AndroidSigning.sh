#!/bin/sh
#
# Written by Henry Kim on 2018.06.21
# Modified by Henry Kim on 2021.08.05
# Normalized by Henry Kim on 2021.09.01
#
HOSTNAME=$(hostname)
jsonConfig="../config/config.json"
if [ ! -f $jsonConfig ]; then
  echo "$HOSTNAME > Error: no config.json in $jsonConfig"
  exit 1
fi
DEBUGGING=0
## Parsing arguments, https://stackoverflow.com/a/14203146
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -p|--platform)
      INPUT_OS="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--file)
      INPUT_FILE="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--root)
      DOC_ROOT="$2"
      shift # past argument
      shift # past value
      ;;
    -iu|--inUrl)
      IN_URL="$2"
      shift # past argument
      shift # past value
      ;;
    -ou|--outUrl)
      OUT_URL="$2"
      shift # past argument
      shift # past value
      ;;
    -tp|--topPath)
      TOP_PATH="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--debug)
      DEBUGGING=1
      shift # past argument
      ;;
    *|-h|--help)  # unknown option
      shift # past argument
      echo "Usage: $SCRIPT_NAME [-p {ios,android}] [-f input_file] [-r document_root] [-u domain] [-d]"
      echo ""
      echo "optional arguments:"
      echo "   -h, --help        show this help message and exit:"
      echo "   -p {ios,android}, --platfor {ios,android}"
      echo "                     assign platform as iOS or Android to processing"
      echo "   -f, --file        assign input_file"
      echo "   -r, --root        assign document root of web server"
      echo "   -iu, --inUrl      assign host url of web site for inbound"
      echo "   -ou, --outUrl     assign host url of web site for outbound"
      echo "   -d, --debug       debugging mode"
      echo ""
      exit
      ;;
  esac
done
####### DEBUG or Not #######
if [[ "$JQ" == "" ]]; then
  if [ -f "/usr/local/bin/jq" ]; then
    JQ="/usr/local/bin/jq"
  elif [ -f "/usr/bin/jq" ]; then
    JQ="/usr/bin/jq"
  else
    JQ="/bin/jq"
  fi
fi
if [ $DEBUGGING -eq 1 ]; then
  config=$(cat $jsonConfig | $JQ '.development')
else
  config=$(cat $jsonConfig | $JQ '.production')
fi
############################
USING_MAIL=$(test $(cat $jsonConfig | $JQ '.mail.domesticEnabled') = true && echo 1 || echo 0)
USING_SLACK=$(test $(cat $jsonConfig | $JQ '.slack.enabled') = true && echo 1 || echo 0)
USING_HTML=$(test $(echo $config | $JQ '.usingHTML') = true && echo 1 || echo 0)
USING_JSON=1
JAR_SIGNER=`which jarsigner` #"/usr/bin/jarsigner"
if test -z $JAR_SIGNER; then
  JAR_SIGNER="/usr/local/opt/openjdk@8/bin/jarsigner"
fi
##### Using Teams or Not, 0=Not Using, 1=Using Teams
USING_TEAMS_WEBHOOK=$(test $(cat $jsonConfig | $JQ '.teams.enabled') = true && echo 1 || echo 0)
TEAMS_WEBHOOK=$(cat $jsonConfig | $JQ '.teams.webhook' | tr -d '"')
############################
USING_APKSIGNING=1   # 1 ?????? ??????, 0 ?????? ?????????
ANDROID_HOME=$(cat $jsonConfig | $JQ '.android.androidHome' | tr -d '"')
OUTPUT_PREFIX=$(echo $config | $JQ '.outputPrefix' | tr -d '"')
ANDROID_BUILDTOOLS="${ANDROID_HOME}/build-tools"
if [ -d $ANDROID_BUILDTOOLS ]; then
  if [ $USING_APKSIGNING -eq 1 ]; then
    APKSIGNER="$(find ${ANDROID_BUILDTOOLS} -name 'apksigner' | sort -r | head -1 | sed -e 's/^\.\/\(.*\)$/\1/')"
    if test -z $APKSIGNER; then
        echo "$HOSTNAME > Error: no apksigner execute"
        exit 1
    fi
  fi
  ZIP_ALIGN="$(find ${ANDROID_BUILDTOOLS} -name 'zipalign' | sort -r | head -1 | sed -e 's/^\.\/\(.*\)$/\1/')"
  if test -z $ZIP_ALIGN; then
      echo "$HOSTNAME > Error: no zipalign execute"
      exit 1
  fi
fi
if test -z $ZIP_ALIGN; then
  ZIP_ALIGN="/Users/dist_account/Library/Android/sdk/build-tools/32.0.0/zipalign"
fi
if test -z $APKSIGNER; then
  APKSIGNER="/Users/dist_account/Library/Android/sdk/build-tools/32.0.0/apksigner"
fi
############################
if test -z $INPUT_FILE; then
    echo "$HOSTNAME > Error: 1??? ????????? ?????? ?????????(????????? ??????) ??????"
    exit
fi
#####
if [ $USING_SLACK -eq 1 ]; then
  SLACK="/usr/local/bin/slack"
  if [ ! -f $SLACK ]; then
    USING_SLACK=0
  else
    SLACK_CHANNEL=$(cat $jsonConfig | $JQ '.slack.channel' | tr -d '"')
  fi
fi
CURL="/usr/bin/curl"
####
##### from config.php
frontEndProtocol=$(echo $config | $JQ '.frontEndProtocol' | tr -d '"')
frontEndPoint=$(echo $config | $JQ '.frontEndPoint' | tr -d '"')
TOP_PATH=$(echo $config | $JQ '.topPath' | tr -d '"')
FRONTEND_POINT="${frontEndProtocol}://${frontEndPoint}"
#####
URL_PATH="${TOP_PATH}"
if [[ "${DOC_ROOT}" == "" ]]; then
  APP_ROOT=".."
else
  APP_ROOT="${DOC_ROOT}/${URL_PATH}"
fi
APP_VERSION=$(find ../android_distributions -name "$INPUT_FILE.json" | xargs dirname $1  | tail -1 |  sed -e 's/.*\/\(.*\)$/\1/')
APP_FOLDER="android_distributions/${APP_VERSION}"
OUTPUT_FOLDER="${APP_ROOT}/${APP_FOLDER}"
HTTPS_PREFIX="${FRONTEND_POINT}/${URL_PATH}/${APP_FOLDER}/"
#####
APK_GOOGLESTORE="${INPUT_FILE}$(cat $jsonConfig | $JQ '.android.outputGoogleStoreSuffix' | tr -d '"')"
USING_BUNDLE_GOOGLESTORE=$(test $(cat $jsonConfig | $JQ '.android.GoogleStore.usingBundleAAB') = true && echo 1 || echo 0)
# if [ $USING_BUNDLE_GOOGLESTORE -eq 1 ]; then
#   APK_GOOGLESTORE="${APK_GOOGLESTORE%.apk}.aab"
# fi
APK_ONESTORE="${INPUT_FILE}$(cat $jsonConfig | $JQ '.android.outputOneStoreSuffix' | tr -d '"')"
USING_BUNDLE_ONESTORE=$(test $(cat $jsonConfig | $JQ '.android.OneStore.usingBundleAAB') = true && echo 1 || echo 0)
# if [ $USING_BUNDLE_ONESTORE -eq 1 ]; then
#   APK_ONESTORE="${APK_ONESTORE%.apk}.aab"
# fi
#####
##### for debugging
if [ $DEBUGGING -eq 1 ]; then
  USING_HTML=0
  USING_MAIL=0
  USING_SLACK=0
  USING_JSON=1
fi
STOREPASS=$(cat $jsonConfig | $JQ '.android.keyStorePassword' | tr -d '"')
KEYSTORE_FILE=$(cat $jsonConfig | $JQ '.android.keyStoreFile' | tr -d '"')
if [ ! -f $KEYSTORE_FILE ]; then
  echo "$HOSTNAME > Error: cannot find keystore file in $KEYSTORE_FILE"
  exit 1
fi
if [ -f "../lang/default.json" ]; then
  language=$(cat "../lang/default.json" | $JQ '.LANGUAGE' | tr -d '"')
  lang_file="../lang/lang_${language}.json"
  CLIENT_NAME=$(cat $lang_file | $JQ '.client.full_name' | tr -d '"')
  TITLE_GOOGLE_STORE=$(cat $lang_file | $JQ '.title.distribution_2nd_signing_google_store' | tr -d '"')
  TITLE_ONE_STORE=$(cat $lang_file | $JQ '.title.distribution_2nd_signing_one_store' | tr -d '"')
fi
#####
outputUnsignedPrefix=$(cat $jsonConfig | $JQ '.android.outputUnsignedPrefix' | tr -d '"')
outputSignedPrefix=$(cat $jsonConfig | $JQ '.android.outputSignedPrefix' | tr -d '"')
#####
# Step 1.1: For Google Store
UNSIGNED_GOOGLE_FILE="${outputUnsignedPrefix}${APK_GOOGLESTORE}"
if [ -f $OUTPUT_FOLDER/$UNSIGNED_GOOGLE_FILE ]; then
    UNZIPALIGNED_GOOGLESTORE="unzipaligned_$APK_GOOGLESTORE"
    SIGNED_FILE_GOOGLESTORE="${outputSignedPrefix}${APK_GOOGLESTORE}"
    if [ -f $OUTPUT_FOLDER/$SIGNED_FILE_GOOGLESTORE ]; then
        rm -f $OUTPUT_FOLDER/$SIGNED_FILE_GOOGLESTORE
    fi
    # if [ $USING_BUNDLE_GOOGLESTORE -eq 1 ]; then
    #   $JAR_SIGNER -sigalg SHA1withRSA \
    #               -digestalg SHA1 \
    #               -keystore $KEYSTORE_FILE \
    #               -storepass "${STOREPASS}" \
    #               $OUTPUT_FOLDER/$UNSIGNED_GOOGLE_FILE "${CLIENT_NAME}" \
    #               -signedjar $OUTPUT_FOLDER/$SIGNED_FILE_GOOGLESTORE
    # else
    $JAR_SIGNER -sigalg SHA1withRSA \
                -digestalg SHA1 \
                -keystore $KEYSTORE_FILE \
                -storepass "${STOREPASS}" \
                $OUTPUT_FOLDER/$UNSIGNED_GOOGLE_FILE "${CLIENT_NAME}" \
                -signedjar $OUTPUT_FOLDER/$UNZIPALIGNED_GOOGLESTORE

    $ZIP_ALIGN -p -f -v 4 $OUTPUT_FOLDER/$UNZIPALIGNED_GOOGLESTORE $OUTPUT_FOLDER/$SIGNED_FILE_GOOGLESTORE
    if [ -f $OUTPUT_FOLDER/$UNZIPALIGNED_GOOGLESTORE ]; then
        rm -f $OUTPUT_FOLDER/$UNZIPALIGNED_GOOGLESTORE
    fi
    if [ $USING_APKSIGNING -eq 1 ]; then
      echo "${STOREPASS}" | $APKSIGNER sign -ks $KEYSTORE_FILE $OUTPUT_FOLDER/$SIGNED_FILE_GOOGLESTORE
      $APKSIGNER verify --verbose $OUTPUT_FOLDER/$SIGNED_FILE_GOOGLESTORE
    fi
    # fi
else
    echo "$HOSTNAME > Error: 1??? ????????? ?????? ??????($OUTPUT_FOLDER/$UNSIGNED_GOOGLE_FILE) ??????"
    exit
fi
#####
# Step 1.2: For One Store
UNSIGNED_ONE_FILE="${outputUnsignedPrefix}${APK_ONESTORE}"
if [ -f $OUTPUT_FOLDER/$UNSIGNED_ONE_FILE ]; then
    UNZIPALIGNED_ONESTORE="unzipaligned_$APK_ONESTORE"
    SIGNED_FILE_ONESTORE="${outputSignedPrefix}${APK_ONESTORE}"
    if [ -f $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE ]; then
        rm -f $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE
    fi
    $JAR_SIGNER -sigalg SHA1withRSA \
                -digestalg SHA1 \
                -keystore $KEYSTORE_FILE \
                -storepass "${STOREPASS}" \
                $OUTPUT_FOLDER/$UNSIGNED_ONE_FILE "${CLIENT_NAME}" \
                -signedjar $OUTPUT_FOLDER/$UNZIPALIGNED_ONESTORE

    $ZIP_ALIGN -p -f -v 4 $OUTPUT_FOLDER/$UNZIPALIGNED_ONESTORE $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE
    if [ -f $OUTPUT_FOLDER/$UNZIPALIGNED_ONESTORE ]; then
        rm -f $OUTPUT_FOLDER/$UNZIPALIGNED_ONESTORE
    fi
    if [ $USING_APKSIGNING -eq 1 ]; then
      echo "${STOREPASS}" | $APKSIGNER sign -ks $KEYSTORE_FILE $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE
      $APKSIGNER verify --verbose $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE
    fi
else
    echo "$HOSTNAME > Error: 1??? ????????? ?????? ??????($OUTPUT_FOLDER/$UNSIGNED_ONE_FILE) ??????"
    # exit
fi


######################################################
if [ $USING_SLACK -eq 1 ]; then
  #####
  # Step 2.1: Send message via Slack for ERROR
  if [ ! -f $OUTPUT_FOLDER/$SIGNED_FILE_GOOGLESTORE ]; then
    $SLACK chat send --text "${HOSTNAME} > ??????????????? 2??? ????????? signing ?????? ????????????!\n\n\n\n${HOSTNAME} > ??????Store - ${OUTPUT_FOLDER}/${SIGNED_FILE_GOOGLESTORE}\n\n" --channel "${SLACK_CHANNEL}" --pretext "${HOSTNAME} > Android 2??? ????????? Signing ?????? for ${APK_GOOGLESTORE}" --color good
    exit
  fi
  if [ -f $OUTPUT_FOLDER/$UNSIGNED_ONE_FILE ]; then
    if [ ! -f $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE ]; then
      $SLACK chat send --text "${HOSTNAME} > ??????????????? 2??? ????????? signing ?????? ????????????!\n\n\n\n${HOSTNAME} > ???Store - ${OUTPUT_FOLDER}/${SIGNED_FILE_ONESTORE}\n\n" --channel "${SLACK_CHANNEL}" --pretext "${HOSTNAME} > Android 2??? ????????? Signing ?????? for ${APK_ONESTORE}" --color good
      exit
    fi
  fi
  #####
  # Step 2.2: Send message via Slack for Success !!!
  $SLACK chat send --text "${HOSTNAME} > ??????????????? 2??? ????????? signing ?????? ???????????????.\n\n\n????????????: \n\n${HOSTNAME} > ??????Store - ${HTTPS_PREFIX}${SIGNED_FILE_GOOGLESTORE}\n${HOSTNAME} > ???Store - ${HTTPS_PREFIX}${SIGNED_FILE_ONESTORE}\n" --channel "${SLACK_CHANNEL}" --pretext "${HOSTNAME} > Android 2??? ????????? Signing ?????? for ${INPUT_FILE}" --color good
fi
######################################################


FILENAME_TODAY=$(echo $INPUT_FILE | sed -e 's/^.*_\([0-9][0-9][0-9][0-9][0-9][0-9]\)$/\1/')
if [ $USING_HTML -eq 1 ]; then
  # Step 3: Change HTML(index.html) file
  OUTPUT_FILENAME_HTML="${OUTPUT_PREFIX}${APP_VERSION}(${VERSION_CODE})_${FILENAME_TODAY}.html"
  HTML_DIST_FILE=${APP_ROOT}/dist_android.html
  HTML_OUTPUT="       <span style=\"position: relative;margin: 0px;right: 0px;float: center;font-size:0.5em;\"><a class=\"button secondary radius\" style=\"white-space:nowrap; height:25px; padding-left:10px; padding-right:10px;\" href=\"${HTTPS_PREFIX}${SIGNED_FILE_GOOGLESTORE}\">Google Playstore ?????????(2??? ?????????)<img src=\"../../../download-res/img/icons8-downloading_updates.png\" style=\"position: relative;margin-top: -6px;margin-left: 18px;right:0px;float:right;width:auto;height:1.5em\"></a></span><span style=\"position: relative;margin: 0px;right: 0px;float: center;font-size:0.5em;\"><a class=\"button secondary radius\" style=\"white-space:nowrap; height:25px; padding-left:10px; padding-right:10px;\" href=\"${HTTPS_PREFIX}${SIGNED_FILE_ONESTORE}\">One Store ?????????(2??? ?????????)<img src=\"../../../download-res/img/icons8-downloading_updates.png\" style=\"position: relative;margin-top: -6px;margin-left: 18px;right: 0px;float:right;width:auto;height:1.5em\"></a></span>"
  HTML_FOR_SED=$(echo $HTML_OUTPUT | sed -e 's/\//\\\//g' | sed -e 's/\./\\\./g')

  if [ -f $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML ]; then
    cp -f $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML.bak
    cd $OUTPUT_FOLDER
    sed "s/^.*title=${INPUT_FILE}.*$/${HTML_FOR_SED}/" $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML > $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML.new
    mv -f $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML.new $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML
    chmod 777 $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML
  fi
  cp -f $HTML_DIST_FILE $HTML_DIST_FILE.bak
  cd $OUTPUT_FOLDER
  sed "s/^.*title=${INPUT_FILE}.*$/${HTML_FOR_SED}/" $HTML_DIST_FILE > $HTML_DIST_FILE.new
  if [ ! -s $HTML_DIST_FILE.new ]; then
    echo "Something ** WRONG ** !!!"
    exit
  fi
  mv -f $HTML_DIST_FILE.new $HTML_DIST_FILE
  chmod 777 $HTML_DIST_FILE
else
  touch $OUTPUT_FOLDER/$OUTPUT_FILENAME_HTML
fi

if [ $USING_MAIL -eq 1 ]; then
  # Step 7: Send download page url to Slack
  SHORT_GIT_LOG="$(/bin/date "+%m")??? ?????? ?????? Android 2??? ?????????"
  if [ $USING_SLACK -eq 1 ]; then
    $SLACK chat send --text "${HOSTNAME} > ${FRONTEND_POINT}/${TOP_PATH}/dist_domestic.php > Go Android > ?????????(2??? ?????????)" --channel "${SLACK_CHANNEL}" --pretext "${HOSTNAME} > Android Download Web Page for ${SHORT_GIT_LOG}" --color good
  fi
  if [ -f "../lang/default.json" ]; then
    language=$(cat "../lang/default.json" | $JQ '.LANGUAGE' | tr -d '"')
    lang_file="../lang/lang_${language}.json"
    APP_NAME=$(cat $lang_file | $JQ '.app.name' | tr -d '"')
  fi
  $CURL --data-urlencode "subject1=[${APP_NAME} > ${HOSTNAME}] Android ?????? 2??? ????????? -" \
  --data-urlencode "subject2=Google Playstore, OneStore ????????? ?????? ?????? ??????" \
  --data-urlencode "message_header=??????????????? 2??? ????????? signing ?????? ???????????????.<br /><br /><br />????????????: <br /><br />??????Store - <a href=${HTTPS_PREFIX}${SIGNED_FILE_GOOGLESTORE}>${HTTPS_PREFIX}${SIGNED_FILE_GOOGLESTORE}</a><br />???Store - <a href=${HTTPS_PREFIX}${SIGNED_FILE_ONESTORE}>${HTTPS_PREFIX}${SIGNED_FILE_ONESTORE}</a><br />" \
  --data-urlencode "message_description=${SHORT_GIT_LOG}<br /><br /><br />" \
  ${FRONTEND_POINT}/${TOP_PATH}/sendmail_domestic.php
fi

if [ $USING_JSON -eq 1 ]; then
  # Step: Find out size of app files
  SIZE_GOOGLESTORE_APK_FILE=$(du -sh ${OUTPUT_FOLDER}/${SIGNED_FILE_GOOGLESTORE} | awk '{print $1}')
  if [ -f $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE ]; then
    SIZE_ONESTORE_APK_FILE=$(du -sh ${OUTPUT_FOLDER}/${SIGNED_FILE_ONESTORE} | awk '{print $1}')
  fi

  OUTPUT_FILENAME_JSON="${INPUT_FILE}.json"
  JSON_FILE=$OUTPUT_FOLDER/$OUTPUT_FILENAME_JSON
  ##################################
  ##### Read from JSON  START ######
  HTML_TITLE=$(cat $JSON_FILE | $JQ -r '.title')
  APP_VERSION=$(cat $JSON_FILE | $JQ -r '.appVersion')
  BUILD_VERSION=$(cat $JSON_FILE | $JQ -r '.buildVersion')
  BUILD_NUMBER=$(cat $JSON_FILE | $JQ -r '.buildNumber')
  BUILD_TIME=$(cat $JSON_FILE | $JQ -r '.buildTime')
  VERSION_KEY=$(cat $JSON_FILE | $JQ -r '.versionKey')
  HTTPS_PREFIX=$(cat $JSON_FILE | $JQ -r '.urlPrefix')
  RELEASE_TYPE=$(cat $JSON_FILE | $JQ -r '.releaseType')
  FILES_ARRAY=$(cat $JSON_FILE | $JQ -r '.files')
  # 2nd APKSigner for Google Play Store
  TITLE[0]=${TITLE_GOOGLE_STORE}
  SIZE[0]="${SIZE_GOOGLESTORE_APK_FILE}"
  URL[0]="${SIGNED_FILE_GOOGLESTORE}"
  PLIST[0]=""
  if [ -f $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE ]; then
    # 2nd APKSigner for One Store
    TITLE[1]=${TITLE_ONE_STORE}
    SIZE[1]="${SIZE_ONESTORE_APK_FILE}"
    URL[1]="${SIGNED_FILE_ONESTORE}"
    PLIST[1]=""
  else
    TITLE[1]=""
    SIZE[1]=""
    URL[1]=""
    PLIST[1]=""
  fi
  # ??????????????? ????????????
  TITLE[2]=$(echo $FILES_ARRAY | $JQ -r '.[2].title')
  SIZE[2]=$(echo $FILES_ARRAY | $JQ -r '.[2].size')
  URL[2]=$(echo $FILES_ARRAY | $JQ -r '.[2].file')
  PLIST[2]=$(echo $FILES_ARRAY | $JQ -r '.[2].plist')
  # ????????????????????? ????????????
  TITLE[3]=$(echo $FILES_ARRAY | $JQ -r '.[3].title')
  SIZE[3]=$(echo $FILES_ARRAY | $JQ -r '.[3].size')
  URL[3]=$(echo $FILES_ARRAY | $JQ -r '.[3].file')
  PLIST[3]=$(echo $FILES_ARRAY | $JQ -r '.[3].plist')
  # 1st APKSigner for Google Play Store
  TITLE[4]=$(echo $FILES_ARRAY | $JQ -r '.[0].title')
  SIZE[4]=$(echo $FILES_ARRAY | $JQ -r '.[0].size')
  URL[4]=$(echo $FILES_ARRAY | $JQ -r '.[0].file')
  PLIST[4]=$(echo $FILES_ARRAY | $JQ -r '.[0].plist')
  # 1st APKSigner for One Store
  TITLE[5]=$(echo $FILES_ARRAY | $JQ -r '.[1].title')
  SIZE[5]=$(echo $FILES_ARRAY | $JQ -r '.[1].size')
  URL[5]=$(echo $FILES_ARRAY | $JQ -r '.[1].file')
  PLIST[5]=$(echo $FILES_ARRAY | $JQ -r '.[1].plist')
  ##
  GIT_LAST_LOG=$(cat $JSON_FILE | $JQ -r '.gitLastLog | gsub("[\\n\\t]"; "")')
  ##### Read from JSON  E N D ######
  ##################################

  ##################################
  ##### JSON Generation START ######
  if [ -f $JSON_FILE ]; then
    cp -f $JSON_FILE $JSON_FILE.bak
  fi
  JSON_STRING=$( $JQ -n \
  --arg title "$HTML_TITLE" \
  --arg av "$APP_VERSION" \
  --arg bv "$BUILD_VERSION" \
  --arg bn "$BUILD_NUMBER" \
  --arg bt "$BUILD_TIME" \
  --arg vk "$VERSION_KEY" \
  --arg rt "${RELEASE_TYPE}" \
  --arg url_prefix "$HTTPS_PREFIX" \
  --arg file1_title "${TITLE[0]}" \
  --arg file1_size "${SIZE[0]}" \
  --arg file1_binary "${URL[0]}" \
  --arg file1_plist "${PLIST[0]}" \
  --arg file2_title "${TITLE[1]}" \
  --arg file2_size "${SIZE[1]}" \
  --arg file2_binary "${URL[1]}" \
  --arg file2_plist "${PLIST[1]}" \
  --arg file3_title "${TITLE[2]}" \
  --arg file3_size "${SIZE[2]}" \
  --arg file3_binary "${URL[2]}" \
  --arg file3_plist "${PLIST[2]}" \
  --arg file4_title "${TITLE[3]}" \
  --arg file4_size "${SIZE[3]}" \
  --arg file4_binary "${URL[3]}" \
  --arg file4_plist "${PLIST[3]}" \
  --arg file5_title "${TITLE[4]}" \
  --arg file5_size "${SIZE[4]}" \
  --arg file5_binary "${URL[4]}" \
  --arg file5_plist "${PLIST[4]}" \
  --arg file6_title "${TITLE[5]}" \
  --arg file6_size "${SIZE[5]}" \
  --arg file6_binary "${URL[5]}" \
  --arg file6_plist "${PLIST[5]}" \
  --arg git_last_log "$GIT_LAST_LOG" \
'{"title": $title, "appVersion": $av, "buildVersion": $bv, "versionKey": $vk,'\
' "buildNumber": $bn, "buildTime": $bt, "urlPrefix": $url_prefix,  "releaseType": $rt, '\
'"files": [ { "title": $file1_title, "size": $file1_size, "file": $file1_binary, "plist": $file1_plist} , '\
'{ "title": $file2_title, "size": $file2_size, "file": $file2_binary, "plist": $file2_plist} , '\
'{ "title": $file3_title, "size": $file3_size, "file": $file3_binary, "plist": $file3_plist} , '\
'{ "title": $file4_title, "size": $file4_size, "file": $file4_binary, "plist": $file4_plist} , '\
'{ "title": $file5_title, "size": $file5_size, "file": $file5_binary, "plist": $file5_plist} , '\
'{ "title": $file6_title, "size": $file6_size, "file": $file6_binary, "plist": $file6_plist} ], '\
'"gitLastLog": $git_last_log}')
  echo "${JSON_STRING}" > $JSON_FILE
  ##### JSON Generation END ########
  ##################################
fi


if [ -f "../lang/default.json" ]; then
  language=$(cat "../lang/default.json" | $JQ '.LANGUAGE' | tr -d '"')
  lang_file="../lang/lang_${language}.json"
  APP_NAME=$(cat $lang_file | $JQ '.app.name' | tr -d '"')
  SITE_URL=$(cat $lang_file | $JQ '.client.short_url' | tr -d '"')
  SITE_ID=$(cat $jsonConfig | $JQ '.users.app.userId' | tr -d '"')
  SITE_PW=$(cat $jsonConfig | $JQ '.users.app.password' | tr -d '"')
  SITE_ID_PW="${SITE_ID}/${SITE_PW}"
fi
if [ $USING_TEAMS_WEBHOOK -eq 1 ]; then
    ########
    BINARY_TITLE="Android ?????????"
    BINARY_FACTS="{
                      \"name\": \"Google Playstore ?????????\",
                      \"value\": \"v${APP_VERSION}(${BUILD_VERSION}) [GoogleStore 2??? ????????? ????????????](${HTTPS_PREFIX}${SIGNED_FILE_GOOGLESTORE}) (${SIZE_GOOGLESTORE_APK_FILE}B)\"
              }"
    if [ -f $OUTPUT_FOLDER/$SIGNED_FILE_ONESTORE ]; then
      BINARY_FACTS=", {
                        \"name\": \"One Store ?????????\",
                        \"value\": \"v${APP_VERSION}(${BUILD_VERSION}) [OneStore 2??? ????????? ????????????](${HTTPS_PREFIX}${SIGNED_FILE_ONESTORE}) (${SIZE_ONESTORE_APK_FILE}B)\"
                }"
    fi
    ########
    THEME_COLOR="619FFA"
    QC_ID=$(cat $jsonConfig | $JQ '.users.qc.userId' | tr -d '"')
    QC_PW=$(cat $jsonConfig | $JQ '.users.qc.password' | tr -d '"')
    ICON=$(cat $jsonConfig | $JQ '.teams.iconImage' | tr -d '"')
    JSON_ALL="{
          \"@type\": \"MessageCard\",
          \"@context\": \"${FRONTEND_POINT}/${TOP_PATH}/dist_domestic.php\",
          \"themeColor\": \"${THEME_COLOR}\",
          \"summary\": \"Android 2nd signing completed\",
          \"sections\": [
              {
                  \"heroImage\": {
                      \"image\": \"${FRONTEND_POINT}/${TOP_PATH}/${ICON}\"
                  }
              },
              {
                  \"activityTitle\": \"${HOSTNAME} > ${BINARY_TITLE} ${APP_NAME}.App\",
                  \"activitySubtitle\": \"$(/bin/date '+%Y.%m.%d %H:%M')\",
                  \"activityImage\": \"${FRONTEND_POINT}/${TOP_PATH}/${ICON}\",
                  \"text\": \"${CLIENT_NAME} ${APP_NAME} ???\",
                  \"facts\": [${BINARY_FACTS}, {
                          \"name\": \"?????? ??? ???????????? ?????????\",
                          \"value\": \"${CLIENT_NAME} ?????? ????????? [${SITE_URL}](${SITE_URL}) (ID/PW: ${SITE_ID_PW})\"
                  }, {
                          \"name\": \"?????? ???????????? (?????? QA???)\",
                          \"value\": \"Domestic QA ????????? [????????????](${FRONTEND_POINT}/${TOP_PATH}/android/dist_android.php) (ID/PW: ${QC_ID}/${QC_PW})\"
                  }],
                  \"markdown\": true
          }]
        }"
    $CURL -H "Content-Type: application/json" -d "${JSON_ALL}" $TEAMS_WEBHOOK
    ##
    # Sync files to Neo2UA (Synology NAS)
    if [ -f ../syncToNasNeo2UA.sh ]; then
      ../syncToNasNeo2UA.sh
    fi
fi
