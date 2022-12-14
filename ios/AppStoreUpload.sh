#!/bin/sh
#
# Written by Henry Kim on 2022.01.20
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
#USING_SLACK=$(test $(cat $jsonConfig | $JQ '.slack.enabled') = true && echo 1 || echo 0)
USING_SLACK=0
##### Using Teams or Not, 0=Not Using, 1=Using Teams
USING_TEAMS_WEBHOOK=$(test $(cat $jsonConfig | $JQ '.teams.enabled') = true && echo 1 || echo 0)
TEAMS_WEBHOOK=$(cat $jsonConfig | $JQ '.teams.webhook' | tr -d '"')
############################
OUTPUT_PREFIX=$(echo $config | $JQ '.outputPrefix' | tr -d '"')
APPSTORE_AGENT_EMAIL=$(cat $jsonConfig | $JQ '.ios.AppStore.uploadApp.agentEmail' | tr -d '"')
APPSTORE_AGENT_PASSWORD=$(cat $jsonConfig | $JQ '.ios.AppStore.uploadApp.agentAppSpecificPassword' | tr -d '"')
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
#####
UPLOAD_IPA_FILE_SUFFIX="$(cat $jsonConfig | $JQ '.ios.AppStore.fileSuffix' | tr -d '"').ipa"
if [[ "${INPUT_FILE}" == *"${UPLOAD_IPA_FILE_SUFFIX}" ]]; then
  UPLOAD_IPA_FILE="${INPUT_FILE}"
  APP_VERSION=$(find ../ios_distributions -name "${INPUT_FILE%%$UPLOAD_IPA_FILE_SUFFIX}.json" | xargs dirname $1 |  sed -e 's/.*\/\(.*\)$/\1/')
else
  UPLOAD_IPA_FILE="${INPUT_FILE}${UPLOAD_IPA_FILE_SUFFIX}"
  APP_VERSION=$(find ../ios_distributions -name "$INPUT_FILE.json" | xargs dirname $1 |  sed -e 's/.*\/\(.*\)$/\1/')
fi
APP_FOLDER="ios_distributions/${APP_VERSION}"
OUTPUT_FOLDER="${APP_ROOT}/${APP_FOLDER}"
HTTPS_PREFIX="${FRONTEND_POINT}/${URL_PATH}/${APP_FOLDER}/"
#####
##### for debugging
if [ $DEBUGGING -eq 1 ]; then
  USING_SLACK=0
  USING_TEAMS_WEBHOOK=0
fi
if [ -f "../lang/default.json" ]; then
  language=$(cat "../lang/default.json" | $JQ '.LANGUAGE' | tr -d '"')
  lang_file="../lang/lang_${language}.json"
  CLIENT_NAME=$(cat $lang_file | $JQ '.client.full_name' | tr -d '"')
fi
#####
# Step 1.1: For App Store
if [ -f $OUTPUT_FOLDER/$UPLOAD_IPA_FILE ]; then
    SIZE_UPLOAD_IPA_FILE=$(du -sh ${OUTPUT_FOLDER}/${UPLOAD_IPA_FILE} | awk '{print $1}')
    ERROR=$(xcrun altool --upload-app -t ios -f "$OUTPUT_FOLDER/$UPLOAD_IPA_FILE" -u "${APPSTORE_AGENT_EMAIL}" -p "${APPSTORE_AGENT_PASSWORD}")
    if [ "$ERROR" != "" ]; then
      echo "$HOSTNAME > Xcrun altool output: ${ERROR}"
      exit
    fi
else
    echo "$HOSTNAME > Error: App Store IPA ??????($OUTPUT_FOLDER/$UPLOAD_IPA_FILE) ??????"
    exit
fi


######################################################
if [ $USING_SLACK -eq 1 ]; then
  #####
  # Step 2: Send message via Slack for Success !!!
  $SLACK chat send --text "${HOSTNAME} > App Store ????????? ??????!" --channel "${SLACK_CHANNEL}" --pretext "${HOSTNAME} > App Store upload ?????? for ${UPLOAD_IPA_FILE}" --color good
fi
######################################################


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
  BINARY_TITLE="iOS App Store ?????????"
  BINARY_FACTS="{
                    \"name\": \"App Store ???????????? IPA\",
                    \"value\": \"v${APP_VERSION}(${BUILD_VERSION}) [App Store IPA ????????????](${HTTPS_PREFIX}${UPLOAD_IPA_FILE}) (${SIZE_UPLOAD_IPA_FILE}B)\"
            }"
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
fi