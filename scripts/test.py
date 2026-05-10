#!/usr/bin/env python3
import sys
import subprocess
from utils import run_command, ensure_gut

def main():
    if ensure_gut():
        run_command(["godot", "--headless", "-e", "--quit"], "Indexing GUT Assets")

    test_command = [
        "godot", "--headless", "--path", ".",
        "-s", "addons/gut/gut_cmdln.gd",
        "-gdir=res://tests", "-ginclude_subdirs", "-gexit"
    ]
    
    success = run_command(test_command, "Running Unit Tests (GUT)")
    
    if success:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
