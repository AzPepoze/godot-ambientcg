import subprocess
import sys

def run_dev_mode():
    godot_command = "godot"
    
    cmd = [godot_command, "-e", "--debug-canvas-item-selection"]
    
    print(f"Launching Godot in UI Debug Mode...")
    print(f"Command: {' '.join(cmd)}")
    try:
        subprocess.run(cmd)
    except FileNotFoundError:
        print("Error: 'godot' command not found in PATH.")
        sys.exit(1)

if __name__ == "__main__":
    run_dev_mode()
