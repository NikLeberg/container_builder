#!/usr/bin/env bash

# Get all changed files between the current branch and main.
# Source: https://github.com/actions/checkout/issues/296
latest_main_commit=$(git rev-parse "refs/remotes/origin/main")
current_commit=$(git rev-parse HEAD)
changed_files=$(git diff --name-only $latest_main_commit $current_commit)

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
# of each registry. This then builds two JSON arrays that hold the containers of
# each registry that needs to be updated.
dockerhub=$1
github=$2
changed_dockerhub="["
changed_github="["
for container in ${changed_containers[@]}; do
    for d_container in $dockerhub; do
        if [ "$d_container" == "$container" ]; then
            changed_dockerhub+="\"$container\","
        fi
    done
    for g_container in ${github[@]}; do
        if [ "$g_container" == "$container" ]; then
            changed_github+="\"$container\","
        fi
    done
done
if [ "$changed_dockerhub" == "[" ]; then
    changed_dockerhub=""
else
    changed_dockerhub="${changed_dockerhub::-1}]"
fi
if [ "$changed_github" == "[" ]; then
    changed_github=""
else
    changed_github="${changed_github::-1}]"
fi
echo "Containers from DockerHub that need to be updated: $changed_dockerhub"
echo "Containers from GitHub registry that need to be updated: $changed_github"

# Set step output for GitHub Action.
echo "::set-output name=dockerhub-changed::$changed_dockerhub"
echo "::set-output name=github-changed::$changed_github"
