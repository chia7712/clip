#!/bin/bash

while [[ $# -gt 0 ]]; do
  case "$1" in
  --command)
    command=$2
    shift 2
    ;;
  --loop)
    loop=$2
    shift 2
    ;;
  --pull_request)
    pull_request=$2
    shift 2
    ;;
  --patch)
    patch=$2
    shift 2
    ;;
  --branch)
    branch=$2
    shift 2
    ;;
  --repo)
    repo=$2
    shift 2
    ;;
  *)
    break
    ;;
  esac
done

if [[ -z $command ]]; then
  echo "--command \"\" is required"
  exit 2
fi

if [[ -z "$loop" ]]; then
  echo "--loop \"\" is required"
  exit 2
fi

if [[ -z "$branch" ]]; then
  branch="trunk"
fi

if [[ -z "$repo" ]]; then
  repo="repo"
fi

if [[ -n "$pull_request" ]] && [[ "$pull_request" != "" ]]; then
  cd ~/"$repo" || exit
  git checkout -- .
  git clean -df
  git pull
  git checkout $branch
  git pull
  git branch -D "$pull_request"
  git fetch origin pull/"$pull_request"/head:"$pull_request"
  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"
  git merge "$pull_request" --no-commit --no-ff
  git reset HEAD
else
  cd ~/"$repo" || exit
  git checkout -- .
  git clean -df
  git pull
  git checkout $branch
  git pull
fi

if [[ -f "$patch" ]]; then
  cd ~/"$repo" || exit
  git apply "$patch" --stat
  git apply "$patch"
fi

echo "command: $command"
echo "loop: $loop"
echo "pull_request: $pull_request"

cd ~/"$repo" || exit
git diff --stat

for i in $(seq 1 "$loop");
do
  echo "-------------------[index:$i]--------------------"

  $command
  
  if [[ "$?" != "0" ]]; then
    exit 2
  fi

done

