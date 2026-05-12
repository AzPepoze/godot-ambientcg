#!/usr/bin/env python3
import sys
import subprocess
from utils import run_command, ensure_gut

def main():
    format_success = run_command(
        ["uv", "run", "task", "format"],
        "Formatting Code (gdformat)"
    )

    lint_success = run_command(
        ["uv", "run", "task", "lint"],
        "Running Linting (gdlint)"
    )
    
    print("")
    test_success = run_command(
        ["uv", "run", "task", "test"],
        "Running Unit Tests (GUT)"
    )

    print("")
    if format_success and lint_success and test_success:
        print("=== Check Complete: ALL PASSED ===")
        sys.exit(0)
    else:
        print("=== Check Complete: FAILED ===")
        sys.exit(1)

if __name__ == "__main__":
    main()
