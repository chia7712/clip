#!/bin/bash

help="[--source to parse the failed tests. support local file and remote log url] [--onlyClass to include only test class]"
source=""
onlyClass="false"
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "help" ]]; then
    echo "$help"
    exit 0
  fi
  if [[ "$1" == "--source" ]]; then
    shift
    source=$1
  fi

  if [[ "$1" == "--onlyClass" ]]; then
    shift
    onlyClass=$1
  fi

  shift
done

if [[ "$source" == "" ]]; then
  echo $help
  exit 2
fi

# Using file to be a hash map since map function is no supported by all shells yet
cacheFolder=$(mktemp -d)

# download the file to to parse
if [[ "$source" == "http"* ]]; then
  file="$cacheFolder/log.txt"
  wget $source -O "$file"
else
  file=$source
fi

command="./gradlew cleanTest"
while IFS= read -r line; do
  # [2024-03-16T07:16:09.375Z] Gradle Test Run :metadata:test > Gradle Test Executor 92 > QuorumControllerTest > testBootstrapZkMigrationRecord() FAILED
  if [[ "$line" == *" FAILED"* ]]; then
    # :metadata:test
    module=$(echo $line | cut -d' ' -f 5)
    moduleName=$(echo -n $module | shasum)
    moduleCacheFile="$cacheFolder/kafka-$moduleName"

    # create cache file
    if [[ ! -f "$moduleCacheFile" ]]; then
      echo "$module" >"$moduleCacheFile"
    fi

    # QuorumControllerTest
    testClassLine=$(echo $line | cut -d'>' -f 3)
    # remove space
    testClass=$(echo $testClassLine | cut -d' ' -f 1)
    # case 1 testBootstrapZkMigrationRecord() FAILED
    testCaseLine=$(echo $line | cut -d'>' -f 4)
    # case 2 testSeparateOffsetsTopic FAILED
    testCaseLine=$(echo $testCaseLine | cut -d'(' -f 1)
    testCase=$(echo $testCaseLine | cut -d' ' -f 1)

    # load all cache to de-duplicate tests
    moduleCache=$(cat "$moduleCacheFile")
    if [[ "$onlyClass" == "true" ]]; then
      if [[ "$moduleCache" != *"$testClass"* ]]; then
        echo "$moduleCache --tests $testClass" >"$moduleCacheFile"
      fi
    else
      if [[ "$moduleCache" != *"$testClass.$testCase"* ]]; then
        echo "$moduleCache --tests $testClass.$testCase" >"$moduleCacheFile"
      fi
    fi
  fi

done \
  < \
  "$file"

for entry in "$cacheFolder"/kafka-*; do
  command="$command $(cat "$entry")"
done

echo "$command"
