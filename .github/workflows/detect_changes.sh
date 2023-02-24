#!/usr/bin/env bash

# Get all changed files between the current branch and main.
# Source: https://github.com/actions/checkout/issues/296
latest_main_commit=$(git rev-parse "refs/remotes/origin/main")
current_commit=$(git rev-parse HEAD)
if [ "$latest_main_commit" == "$current_commit" ]; then
    # on main, compare with previous commit
    changed_files=$(git diff --name-only $latest_main_commit~ $current_commit)
else
    # on a branch, compare with latest main
    changed_files=$(git diff --name-only $latest_main_commit $current_commit)
fi

# Loop over all toplevel folders, every folder defines a container. Add the name
# of the container to the change_containers array if either a file inside its
# own direcory was changed or a file in the .github folder (CI).
changed_containers=()
for container in */; do
    container=${container::-1}
    echo "Checking if files of container '$container' were changed..."
    for file in ${changed_files[@]}; do
        if [[ $file == $container* || $file == "."* ]]; then
            echo "  File '$file' was changed: Adding container to update list."
            changed_containers+=($container)
            break
        fi
    done
done

# From the detected containers, compare them with the given lists of containers
# of each stage. This then builds three JSON arrays that hold the containers of
# each stage that needs to be updated.
stage_1=$1
stage_2=$2
stage_3=$3
changed_stage_1="["
changed_stage_2="["
changed_stage_3="["
for container in ${changed_containers[@]}; do
    for d_container in $stage_1; do
        if [ "$d_container" == "$container" ]; then
            changed_stage_1+="\"$container\","
        fi
    done
    for d_container in $stage_2; do
        if [ "$d_container" == "$container" ]; then
            changed_stage_2+="\"$container\","
        fi
    done
    for d_container in $stage_3; do
        if [ "$d_container" == "$container" ]; then
            changed_stage_3+="\"$container\","
        fi
    done
done
if [ "$changed_stage_1" == "[" ]; then
    changed_stage_1=""
else
    changed_stage_1="${changed_stage_1::-1}]"
fi
if [ "$changed_stage_2" == "[" ]; then
    changed_stage_2=""
else
    changed_stage_2="${changed_stage_2::-1}]"
fi
if [ "$changed_stage_3" == "[" ]; then
    changed_stage_3=""
else
    changed_stage_3="${changed_stage_3::-1}]"
fi
echo "Containers from stage 1 that need to be updated: $changed_stage_1"
echo "Containers from stage 2 that need to be updated: $changed_stage_2"
echo "Containers from stage 3 that need to be updated: $changed_stage_3"

# Set step output for GitHub Action.
echo "stage_1=$changed_stage_1" >> $GITHUB_OUTPUT
echo "stage_2=$changed_stage_2" >> $GITHUB_OUTPUT
echo "stage_3=$changed_stage_3" >> $GITHUB_OUTPUT
