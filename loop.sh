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
  loop="1"
fi

if [[ -n "$repo" ]] && [[ "$repo" != "" ]]; then
  # change working directory
  cd "$repo" || exit
fi

# cleanup
git checkout -- . && git clean -df

# update
git pull

# checkout to specify branch
if [[ -n "$branch" ]] && [[ "$branch" != "" ]]; then
  git checkout "$branch"
  git pull
fi

if [[ -f "$patch" ]]; then
  git apply "$patch"
fi

echo "command: $command"
echo "loop: $loop"

git diff --stat

for i in $(seq 1 "$loop");
do
  echo "-------------------[index:$i]--------------------"

  $command
  
  if [[ "$?" != "0" ]]; then
    exit 2
  fi

done

