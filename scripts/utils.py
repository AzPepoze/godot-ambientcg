import subprocess
import urllib.request
import json
import tarfile
import os
import shutil

def get_godot_command():
    # Try environment variable first (useful for custom CI setups)
    env_godot = os.environ.get("GODOT")
    if env_godot:
        print(f"Debug: GODOT env var found: {env_godot}")
        # If it's a direct path that exists, use it
        if os.path.exists(env_godot):
            return env_godot
        # If it's in PATH, use it
        if shutil.which(env_godot):
            return env_godot
        print(f"Debug: GODOT env var '{env_godot}' not found on disk or in PATH.")

    # Try the default command
    if shutil.which("godot"):
        return "godot"
    
    # On Windows, try common variations if 'godot' isn't found directly
    if os.name == "nt":
        print(f"Debug: Scanning common Windows names. PATH: {os.environ.get('PATH')[:100]}...")
        for name in ["godot.exe", "Godot", "godot4", "godot4.exe"]:
            found = shutil.which(name)
            print(f"Debug: Checking '{name}': {'FOUND' if found else 'NOT FOUND'}")
            if found:
                return name
    
    # Fallback to 'godot' and let it fail if not found
    return "godot"

def run_command(command, description):
    # If the command starts with 'godot', use our helper to find the correct executable
    if command and command[0] == "godot":
        command[0] = get_godot_command()

    print(f"=== {description} ===")
    use_shell = os.name == "nt"
    try:
        subprocess.run(command, check=True, text=True, shell=use_shell)
        return True
    except subprocess.CalledProcessError:
        print(f"\nError during {description}!")
        return False
    except FileNotFoundError:
        print(f"\nError: Executable '{command[0]}' not found in PATH.")
        return False

def get_latest_godot_version():
    fallback = "4.3"
    token = os.environ.get("GITHUB_TOKEN")
    url = "https://api.github.com/repos/godotengine/godot/releases/latest"
    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"token {token}")
    
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            return data["tag_name"].replace("-stable", "")
    except Exception as e:
        print(f"Warning: Failed to fetch latest Godot version ({e}). Using fallback: {fallback}")
        return fallback

def ensure_gut():
    if os.path.exists("addons/gut"):
        return False
    print("=== Downloading Latest GUT ===")
    
    token = os.environ.get("GITHUB_TOKEN")
    url = "https://api.github.com/repos/bitwes/Gut/releases/latest"
    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"token {token}")
    
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            tarball_url = data["tarball_url"]
    except Exception as e:
        print(f"Error: Failed to fetch latest GUT release ({e}).")
        return False

    file_path, _ = urllib.request.urlretrieve(tarball_url)
    with tarfile.open(file_path, "r:gz") as tar:
        for member in tar.getmembers():
            if "addons/gut/" in member.name:
                parts = member.name.split("/")
                member.name = "/".join(parts[1:])
                tar.extract(member, path=".")
    os.remove(file_path)
    return True

def clean_project():
    paths = ["AmbientCG", ".godot"]
    for path in paths:
        if os.path.exists(path):
            shutil.rmtree(path)
            print(f"Removed: {path}")
