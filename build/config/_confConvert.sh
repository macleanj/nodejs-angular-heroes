#!/bin/bash
# Script to convert configuration files to environment variable syntax

now=$(date +%Y-%m-%d\ %H:%M:%S)
programName=$(basename $0)
programDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
baseName=$(echo ${programName} | sed -e 's/.sh//g')
envDir="env.files"
debug=0

cd $programDir
rm -rf ${envDir}
mkdir -p ${envDir}

# Execute tag creation first
CICD_TAGS_NAME=$1
GIT_COMMIT_SHORT=$2
$programDir/_prepTagEnvConvert.sh $CICD_TAGS_NAME $GIT_COMMIT_SHORT

for file in ${envDir}/tag_env.conf $(ls *.conf); do
  [ $debug -eq 1 ] && echo "Processing $file"

  # Get basename of the file
  baseNameFile=$(echo ${file} | sed -e 's/.*\///g' | sed -e 's/.conf//g')
  
  # Prepare file(s) for environment variable format
  echo -n > ${envDir}/${baseNameFile}.env

  # Prepare file(s) for groovy format
  echo -n > ${envDir}/${baseNameFile}.groovy

  # Convert
  OLDIFS=$IFS
  IFS=$'\n'
  for env in $(cat $file | egrep -v "^#|^[[:space:]]"); do
    [ $debug -eq 1 ] && echo "RAW  : $env"
    key=$(echo $env | awk -F "=" '{print $1}' | awk '{$1=$1};1')
    value=$(echo $env | sed -e 's/^[-_a-zA-Z0-9]*=//g' | sed -e 's/[#].*//g' | awk '{$1=$1};1')
    [ $debug -eq 1 ] && echo "SPLIT: $key=$value"

    # Quote value in case not quoted
    [[ ! $value =~ ^\" ]] && value="\"$value\""

    # Environment variable format
    echo "$key=$value" >> ${envDir}/${baseNameFile}.env

    # Environment groovy format
    echo "env.$key=$value" >> ${envDir}/${baseNameFile}.groovy

  done
  IFS=$OLDIFS
done
