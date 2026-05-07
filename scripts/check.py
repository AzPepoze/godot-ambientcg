#!/usr/bin/env python3
import sys
import subprocess
from utils import run_command, ensure_gut

def main():
    lint_success = run_command(
        ["uv", "tool", "run", "--from", "gdtoolkit", "gdlint", "addons/ambientcg"],
        "Running Linting (gdlint)"
    )
    
    print("")
    if ensure_gut():
        run_command(["godot", "--headless", "-e", "--quit"], "Indexing GUT Assets")

    test_command = [
        "godot", "--headless", "--path", ".",
        "-s", "addons/gut/gut_cmdln.gd",
        "-gdir=res://tests", "-ginclude_subdirs", "-gexit"
    ]
    
    test_success = run_command(test_command, "Running Unit Tests (GUT)")

    print("")
    if lint_success and test_success:
        print("=== Check Complete: ALL PASSED ===")
        sys.exit(0)
    else:
        print("=== Check Complete: FAILED ===")
        sys.exit(1)

if __name__ == "__main__":
    main()
