#!/usr/bin/env python3

import os, subprocess, json
from dataclasses import dataclass
from pathlib import Path


@dataclass
class ContainerVariant:
    name: str
    tags: list
    dockerfile: str
    platforms: list
    args: list
    dependsOn: list
    intermediate: bool
    maximizeBuildSpace: bool
    testScript: str
    trivySkip: bool
    dockleSkip: bool
    dockleAcceptExt: str

    @staticmethod
    def tryMapFromJson(json: dict):
        name = json.get("name")
        tags = json.get("tags")
        if isinstance(tags, str):
            tags = [tags]
        dockerfile = json.get("dockerfile", "Dockerfile")
        platforms = json.get("platforms", ["linux/amd64"])
        args = json.get("args", [])
        dependsOn = json.get("dependsOn", "")
        intermediate = json.get("intermediate", False)
        maximizeBuildSpace = json.get("maximizeBuildSpace", False)
        testScript = json.get("testScript", "")
        trivySkip = json.get("trivySkip", False)
        dockleSkip = json.get("dockleSkip", False)
        dockleAcceptExt = json.get("dockleAcceptExt", "")
        if name and isinstance(name, str) and tags and isinstance(tags, list):
            return ContainerVariant(name, tags, dockerfile, platforms, args, dependsOn, intermediate, maximizeBuildSpace, testScript, trivySkip, dockleSkip, dockleAcceptExt)
        else:
            print(f"Ill formed containers.json entry '{json}' is not valid. Ignoring.")
            return None

    def getVariantName(self) -> str:
        return f"{self.name}:{self.tags[0]}"

    def getTaggedNames(self) -> list:
        return [f"{self.name}:{tag}" for tag in self.tags]

    def getGHAMatrix(self) -> dict:
        d = {k:v for k,v in vars(self).items() if k not in ("dependsOn")}
        d["mainTag"] = d["tags"][0]
        for k in d.keys():
            if isinstance(d[k], list):
                d[k] = "\n".join(d[k])
        return d


# Function to run a command in a shell an get the output.
def run(cmd):
    return subprocess.check_output(cmd).decode("utf-8").strip()

# Load all available containers.json files.
def loadAllContainersJson() -> list:
    containers = []
    for fileName in Path(".").glob("**/containers.json"):
        containers += loadContainersJson(fileName)
    return containers

# Load containers.json file.
def loadContainersJson(fileName) -> list:
    with open(fileName) as jsonFile:
        print(f"Found containers in {fileName}:")
        containers = json.load(jsonFile, object_hook=ContainerVariant.tryMapFromJson)
        containers = [c for c in containers if c]
        for c in containers:
            print(f"  {c.getVariantName()}")
        return containers

def containerValid(c: ContainerVariant, tags: list) -> bool:
    dockerfile = Path(f"{c.name}/{c.dockerfile}")
    if not dockerfile.exists():
        print(f"Dockerfile '{c.dockerfile}' for container '{c.getVariantName()}' not found.")
        return False
    if c.dependsOn and c.dependsOn not in tags:
        print(f"Dependency '{c.dependsOn}' for container '{c.getVariantName()}' is not defined.")
        return False
    testScript = Path(f"{c.name}/{c.testScript}")
    if c.testScript and not testScript.exists():
        print(f"Test script '{c.testScript}' for container '{c.getVariantName()}' not found.")
        return False
    if c.testScript and not os.access(testScript, os.X_OK):
        print(f"Test script '{c.testScript}' for container '{c.getVariantName()}' is not excutable.")
        return False
    return True

def tagsUnique(tags: list) -> bool:
    tmpTags = tags[:]
    for tag in set(tmpTags):
        tmpTags.remove(tag)
    allUnique = True
    for tag in tmpTags:
        print(f"Container with tagged name '{tag}' is defined multiple times.")
        allUnique = False
    return allUnique

def containersValid(containers: list) -> bool:
    tags = [tag for c in containers for tag in c.getTaggedNames()]
    unique = tagsUnique(tags)
    valid = [containerValid(c, tags) for c in containers]
    return all(valid) and unique

# Resolve dependencies and assign containers to the available CI stages.
def resolveContainerDependencies(containers: list) -> list:
    stages = [containers]
    didChanges = True
    while didChanges:
        lastStage = stages[-1]
        newStage = []
        tags = [tag for c in lastStage for tag in c.getTaggedNames()]
        for c in lastStage:
            if c.dependsOn in tags:
                newStage.append(c)
        if len(newStage) > 0:
            didChanges = True
            stages[-1] = [c for c in lastStage if c not in newStage]
            stages.append(newStage)
        else:
            didChanges = False
    return stages

def printStages(stages: list) -> None:
    for i,s in enumerate(stages):
        print(f"Stage {i+1}:")
        for c in s:
            print(f"  {c.getVariantName()}")

# Get all changed files between the current branch and main.
# Source: https://github.com/actions/checkout/issues/296
def getChangedFiles():
    print("File changes:")
    latestMainCommit = run(["git", "rev-parse", "refs/remotes/origin/main"])
    currentCommit = run(["git", "rev-parse", "HEAD"])
    print(f"  main commit: {latestMainCommit}")
    print(f"  HEAD commit: {currentCommit}")
    changedFiles = []
    if latestMainCommit == currentCommit:
        # On main, compare with previous commit
        changedFiles = run(["git", "diff", "--name-only", f"{latestMainCommit}~", currentCommit]).split("\n")
    else:
        # On a branch, compare with latest main
        changedFiles = run(["git", "diff", "--name-only", latestMainCommit, currentCommit]).split("\n")
    print(f"  Changed files: {changedFiles}")

    # Check if git commit log contains "[ci::ignore_workflow_change]" directive.
    # When it exists, then changed files in .github/workflows do not force
    # rebuild of all containers.
    gitLogs = run(["git", "log", "--ancestry-path", f"{latestMainCommit}..{currentCommit}"]).split("\n")
    if any(["[ci::ignore_workflow_change]" in line for line in gitLogs]):
        print("  Directive '[ci::ignore_workflow_change]' found.")
        print("  Filtering out all changes to '.github/workflows'.")
        changedFiles = [f for f in changedFiles if not "github/workflows" in f]

    return changedFiles

def getChangedContainers(containers: list, changedFiles: list) -> list:
    changedContainers = []
    folderNames = set([c.name for c in containers])
    for file in changedFiles:
        folder = Path(file).parts[0]
        if folder in folderNames:
            for c in containers:
                if c.name == folder:
                    changedContainers.append(c)

    print("Containers with changes:")
    for c in changedContainers:
        print(f"  {c.getVariantName()}")

    # Overwrite with all containers if anything in .github/workflows changes.
    if any([".github/workflows" in file for file in changedFiles]):
        print("Force rebuild all containers, '.github/workflows' did change.")
        changedContainers = containers

    return changedContainers

def reduceStagesToChangedAndDependencies(stages: list, changedContainers: list) -> None:
    for i, stage in enumerate(stages):
        toKeep = []
        if i == 0:
            toKeep = changedContainers
        else:
            prevStageTags = [c.getVariantName() for c in stages[i-1]]
            dependants = [c for c in stage if c.dependsOn in prevStageTags]
            toKeep = changedContainers + dependants
        stages[i] = [c for c in stage if c in toKeep]

# Build the GHA (GitHub Actions) matrix definitions for the containers.
def buildGHAMatrices(stages: list) -> list:
    return [{"include": [c.getGHAMatrix() for c in s]} for s in stages if s]

# Set step output for GHA, prints to STDIO if not in CI.
def setGHAOutput(matrices: list) -> None:
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as ghOutput:
            for i, matrix in enumerate(matrices):
                matrixJson = json.JSONEncoder().encode(matrix)
                print(f"builderMatrixStage{i+1}={matrixJson}", file=ghOutput)
    else:
        for i, matrix in enumerate(matrices):
            print(f"Stage {i+1} matrix:")
            matrixJson = json.JSONEncoder(indent="  ").encode(matrix)
            print(matrixJson)


def main():
    containers = loadAllContainersJson()
    if not containersValid(containers):
        return

    stages = resolveContainerDependencies(containers)
    printStages(stages)

    changedFiles = getChangedFiles()
    changedContainers = getChangedContainers(containers, changedFiles)

    reduceStagesToChangedAndDependencies(stages, changedContainers)
    printStages(stages)

    matrices = buildGHAMatrices(stages)
    setGHAOutput(matrices)


if __name__ == "__main__":
    main()
