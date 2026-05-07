#!/usr/bin/env python3
import os
from utils import get_latest_godot_version

def main():
    version = get_latest_godot_version()
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"version={version}\n")
    else:
        print(version)

if __name__ == "__main__":
    main()
