#!/bin/bash

help="[--accounts github account to count commits] [--projects github repos to search. format: org/project] [--token github token to access APIs]"
accounts=""
projects=""
token=""
since="1970-01-01"
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "help" ]]; then
    echo "$help"
    exit 0
  fi
  if [[ "$1" == "--accounts" ]]; then
    shift
    accounts=$1
  fi
  if [[ "$1" == "--projects" ]]; then
    shift
    projects=$1
  fi
  if [[ "$1" == "--token" ]]; then
    shift
    token=$1
  fi
  if [[ "$1" == "--since" ]]; then
    shift
    since=$1
  fi
  shift
done

if [[ "$accounts" == "" ]]; then
  echo "--accounts is required"
  exit 2
fi

if [[ "$projects" == "" ]]; then
  echo "--projects is required"
  exit 2
fi

# we need Github token to avoid connection limit
if [[ "$token" == "" ]]; then
  echo "--token is required"
  exit 2
fi

# generate csv header
IFS=',' read -ra projects_array <<<"$projects"
header=""
for project in "${projects_array[@]}"; do
  if [[ "$header" == "" ]]; then
    header="$project"
  else
    header="$header,$project"
  fi
done
echo "ACCOUNT,$header,SUM"

# generate csv value
IFS=',' read -ra accounts_array <<<"$accounts"
for account in "${accounts_array[@]}"; do
  sum=0
  values=""
  for project in "${projects_array[@]}"; do
    # reference: https://gist.github.com/0penBrain/7be59a48aba778c955d992aa69e524c5
    result=$(curl -I -s -k -H "Authorization: Bearer $token" "https://api.github.com/repos/$project/commits?author=$account&per_page=1&since=$since" | sed -n '/^[Ll]ink:/ s/.*"next".*page=\([0-9]*\).*"last".*/\1/p')
    if [[ "$result" != "" ]]; then
      values="$values,$result"
      sum=$((sum + result))
    else
      values="$values,0"
    fi
  done
  echo "$account$values,$sum"
done
