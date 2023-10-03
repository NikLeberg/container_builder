#!/usr/bin/env python3
import os, subprocess, sys, re

# Function to run a command in a shell an get the output.
def run(cmd):
    return subprocess.check_output(cmd).decode("utf-8").strip()

# Get the number of stages and their respective images from cli arguments.
print("Parsing cli arguments...")
stages = []
for i, arg in enumerate(sys.argv[1:]):
    stage = arg.split(" ")
    stages.append(stage)
    print(f"  Stage {i+1} images: {stage}")

# Get all changed files between the current branch and main.
# Source: https://github.com/actions/checkout/issues/296
print("Detecting changes...")
latest_main_commit = run(["git", "rev-parse", "refs/remotes/origin/main"])
current_commit = run(["git", "rev-parse", "HEAD"])
print(f"  main commit: {latest_main_commit}")
print(f"  HEAD commit: {current_commit}")
if latest_main_commit == current_commit:
    # On main, compare with previous commit
    changed_files = run(["git", "diff", "--name-only", f"{latest_main_commit}~", current_commit]).split("\n")
else:
    # On a branch, compare with latest main
    changed_files = run(["git", "diff", "--name-only", latest_main_commit, current_commit]).split("\n")
print(f"  Changed files: {changed_files}")

# Get top-level folders aka containers.
containers = []
for container in os.listdir("."):
    if os.path.isdir(container) and not container.startswith("."):
        containers.append(container)

# Check if git commit log contains "[ci::<directive>::<container>]" directives.
# When directive is force, then the given container is forced to be rebuild
# (+its dependents). When directive ignore, then the changed files of the given
# container are ignored. This also works for ignoring dependants. Special
# container "*" globs all available containers.
print("Parsing git commit logs...")
git_logs = run(["git", "log", "--ancestry-path", f"{latest_main_commit}..{current_commit}"]).split("\n")
to_force = []
to_ignore = []
for log in git_logs:
    for match in re.finditer(r"\[ci::force::(.+?)\]", log):
        force = match.group(1)
        if force == "*": to_force.extend(containers)
        else:            to_force.append(force)
    for match in re.finditer(r"\[ci::ignore::(.+?)\]", log):
        ignore = match.group(1)
        if ignore == "*": to_ignore.extend(containers)
        else:             to_ignore.append(ignore)
print(f"  to force:  {to_force}")
print(f"  to ignore: {to_ignore}")

# Add the name of the container to the changed_containers list if a file inside
# its own directory was changed.
print(f"Checking file changes...")
changed_containers = []
for container in containers:
    if container in to_force:
        print(f"  Container '{container}' is forced: Adding to update list.")
        changed_containers.append(container)
    else:
        for file in changed_files:
            if file.startswith(container):
                if container in to_ignore:
                    print(f"  File '{file}' of container '{container}' was changed but it is ignored: NOT adding to update list.")
                else:
                    print(f"  File '{file}' of container '{container}' was changed: Adding to update list.")
                    changed_containers.append(container)
                    break

# Add dependents of changed images to the list of to build images.
# This crude dependency resolution is looped as many stages there are.
print("Resolving dependencies of containers...")
for _ in range(len(stages)):
    for container in containers:
        if os.path.exists(f"./{container}/depends.on"):
            depends = open(f"./{container}/depends.on", "r").read().strip()
            if depends in changed_containers and container not in changed_containers:
                if container not in to_ignore:
                    print(f"  Container '{depends}' was changed and '{container}' depends on it: Adding dependent to update list.")
                    changed_containers.append(container)
                else:
                    print(f"  Container '{depends}' was changed and '{container}' depends on it, which is ignored: NOT adding dependent to update list.")

# Set step output for GitHub Action.
with open(os.environ["GITHUB_OUTPUT"], "a") as gh_output:
    for i in range(len(stages)):
        stage_containers = [container for container in changed_containers if container in stages[i]]
        print(f"Containers from stage {i+1} that need to be updated: {stage_containers}")
        if len(stage_containers):
            print(f"stage_{i+1}={stage_containers}", file=gh_output)
