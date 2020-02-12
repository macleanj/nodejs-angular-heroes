#!/usr/bin/env bash
# Script to prepare environment for tags

now=$(date +%Y-%m-%d\ %H:%M:%S)
programName=$(basename $0)
programDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
baseName=$(echo ${programName} | sed -e 's/.sh//g')
envDir="env.files"
tagFile=${envDir}/tag_env.conf
debug=1

source $programDir/generic.conf
CICD_TAGS_NAME=$1
GIT_COMMIT_SHORT=$2
[[ -z $GIT_COMMIT_SHORT ]] && imageHash="DummyHash1345fa4f3546a3" || imageHash=$GIT_COMMIT_SHORT

buildTagType=$CICD_TAGS_BUILD_TAG
deployTagType=$CICD_TAGS_DEPLOY_TAG

declare -A mapTag2imageType
for mapping in $CICD_TAGS_TAG_MAPPING; do
  key=$(echo $mapping | awk -F "=" '{print $1}')
  value=$(echo $mapping | awk -F "=" '{print $2}')
  mapTag2imageType[$key]=$value
done

# Verify tagTypeKey tag character
if [[ "$CICD_TAGS_NAME" == "" ]] && [[ "$CICD_TAGS_NAME" == "None" ]]; then
  # Not a tag
  buildEnabled=0
else
  # This is a tag
  buildEnabled=1
  currentTag=$CICD_TAGS_NAME
  # Character extraction by expected format
  # - Build: $buildTagType<imageTypeKey>-<version>. Example: bh-1.01
  # - Deploy: $deployTagType<imageTypeKey>-<deployEnvironment>-<version>. Example: dv-prod-1.01
  tagTypeKey="${currentTag:0:1}"
  imageTypeKey="${currentTag:1:1}"
  if [[ "$tagTypeKey" == "${buildTagType}" ]]; then
    envKey="NA"
    versionKey=$(echo $currentTag | awk -F "-" '{print $2}')
  elif [[ "$tagTypeKey" == "${deployTagType}" ]]; then
    envKey=$(echo $currentTag | awk -F "-" '{print $2}')
    versionKey=$(echo $currentTag | awk -F "-" '{print $3}')
  fi
  [ $debug -eq 1 ] && echo "Receiving tag: $currentTag"
  [ $debug -eq 1 ] && echo "tagTypeKey: $tagTypeKey"
  [ $debug -eq 1 ] && echo "imageTypeKey: $imageTypeKey"
  [ $debug -eq 1 ] && echo "envKey: $envKey"
  [ $debug -eq 1 ] && echo "versionKey: $versionKey"

  # tagTypeKey character
  [[ "$tagTypeKey" != "${buildTagType}" && "$tagTypeKey" != "${deployTagType}" ]] && buildEnabled=0
  [ $debug -eq 1 ] && echo -e "1: Enabled: $buildEnabled\n"

  # imageTypeKey character
  tmpKey=" $imageTypeKey "
  [[ ! " ${!mapTag2imageType[@]} " =~ \s*$tmpKey\s* ]] && buildEnabled=0
  [ $debug -eq 1 ] && echo -e "2: Enabled: $buildEnabled"

  # Trailing characters
  if [[ $buildEnabled == 1 ]]; then
    if [[ "$tagTypeKey" == "${buildTagType}" ]]; then
      # Build tag received
      CICD_TAGS_BUILD_IMAGE_TYPE=${mapTag2imageType[$imageTypeKey]}
      CICD_TAGS_BUILD_VERSION=${versionKey}
      [[ ${mapTag2imageType[$imageTypeKey]} == "hash" ]] && CICD_TAGS_BUILD_VERSION=$imageHash

      # Build tag format
      [[ ! $currentTag =~ ^[a-z]+-[0-9.]+$ ]] && buildEnabled=0
      [ $debug -eq 1 ] && echo -e "3: Enabled: $buildEnabled"
    elif [[ "$tagTypeKey" == "${deployTagType}" ]]; then
      # Deploy tag received
      CICD_TAGS_DEPLOY_IMAGE_TYPE=${mapTag2imageType[$imageTypeKey]}
      CICD_TAGS_DEPLOY_ENVIRONMENT=${envKey}
      CICD_TAGS_DEPLOY_VERSION=${versionKey}
      [[ ${mapTag2imageType[$imageTypeKey]} == "hash" ]] && CICD_TAGS_DEPLOY_VERSION=$imageHash

      # Deploy tag format
      [[ ! $currentTag =~ ^[a-z]+-[a-z]+-[0-9.]+$ ]] && buildEnabled=0
      [ $debug -eq 1 ] && echo -e "3: Enabled: $buildEnabled"
      # envKey string
      tmpKey=" $envKey "
      [[ ! " ${CICD_TAGS_DEPLOY_ENV_LIST} " =~ $tmpKey ]] && buildEnabled=0
      [ $debug -eq 1 ] && echo -e "4: Enabled: $buildEnabled"
    fi
    # No else needed. Code is protected earlier
  fi
  [ $debug -eq 1 ] && echo -e "Enabled: $buildEnabled\n"
fi
[ $debug -eq 1 ] && echo "------------------------------------------------------------------------------------------"
[ $debug -eq 1 ] && echo "CICD_TAGS_BUILD_IMAGE_TYPE: $CICD_TAGS_BUILD_IMAGE_TYPE"
[ $debug -eq 1 ] && echo "CICD_TAGS_BUILD_ENVIRONMENT: $CICD_TAGS_BUILD_ENV"
[ $debug -eq 1 ] && echo "CICD_TAGS_BUILD_VERSION: $CICD_TAGS_BUILD_VERSION"
[ $debug -eq 1 ] && echo "------------------------------------------------------------------------------------------"
[ $debug -eq 1 ] && echo "CICD_TAGS_DEPLOY_IMAGE_TYPE: $CICD_TAGS_DEPLOY_IMAGE_TYPE"
[ $debug -eq 1 ] && echo "CICD_TAGS_DEPLOY_ENVIRONMENT: $CICD_TAGS_DEPLOY_ENVIRONMENT"
[ $debug -eq 1 ] && echo "CICD_TAGS_DEPLOY_VERSION: $CICD_TAGS_DEPLOY_VERSION"
[ $debug -eq 1 ] && echo "------------------------------------------------------------------------------------------"
[ $debug -eq 1 ] && echo "Build enabled: $buildEnabled"

echo "CICD_BUILD_ENABLED=\"$buildEnabled\"" > ${tagFile}
if [[ $buildEnabled == 1 ]]; then
  if [[ "$tagTypeKey" == "${buildTagType}" ]]; then
    # Build tag received
    cat >> ${tagFile} <<EOL
CICD_TAGS_TAG_TYPE="build"
CICD_TAGS_IMAGE_TYPE="$CICD_TAGS_BUILD_IMAGE_TYPE"
CICD_TAGS_DEPLOY_ENVIRONMENT="$CICD_TAGS_BUILD_ENV"
CICD_TAGS_ID="$CICD_TAGS_BUILD_VERSION"
CICD_DEPLOY_ENABLED="0"
EOL
  elif [[ "$tagTypeKey" == "${deployTagType}" ]]; then
    # Deploy tag received
    cat >> ${tagFile} <<EOL
CICD_TAGS_TAG_TYPE="deployment"
CICD_TAGS_IMAGE_TYPE="$CICD_TAGS_DEPLOY_IMAGE_TYPE"
CICD_TAGS_DEPLOY_ENVIRONMENT="$CICD_TAGS_DEPLOY_ENVIRONMENT"
CICD_TAGS_ID="$CICD_TAGS_DEPLOY_VERSION"
CICD_DEPLOY_ENABLED="1"
EOL
  else
    cat >> ${tagFile} <<EOL
CICD_TAGS_TAG_TYPE="Other"
CICD_TAGS_IMAGE_TYPE="none""
CICD_TAGS_DEPLOY_ENVIRONMENT="None"
CICD_TAGS_ID="None"
CICD_DEPLOY_ENABLED="0"
EOL
  fi
else
  cat >> ${tagFile} <<EOL
CICD_DEPLOY_ENABLED="0"
EOL
fi