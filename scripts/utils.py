import subprocess
import urllib.request
import json
import tarfile
import os
import shutil

def get_godot_command():
    # Try environment variable first (useful for custom CI setups)
    env_godot = os.environ.get("GODOT")
    # Special handling for Chickensoft setup-godot on Windows CI
    if os.name == "nt" and os.environ.get("GITHUB_ACTIONS") == "true":
        user_home = os.path.expanduser("~")
        godot_dir = os.path.join(user_home, "godot")
        if os.path.exists(godot_dir):
            import glob
            # We saw this structure in 'ls -R': ~/godot/Godot_vX.Y.Z-stable_mono_win64/Godot_*.exe
            matches = glob.glob(os.path.join(godot_dir, "Godot_*", "Godot_*.exe"))
            if matches:
                # Prioritize non-console version
                main_version = [m for m in matches if "_console.exe" not in m.lower()]
                result = os.path.abspath(main_version[0] if main_version else matches[0])
                print(f"Debug: CI-Specific Resolution: {result}")
                return result

    # Try environment variable
    env_godot = os.environ.get("GODOT")
    if env_godot:
        if os.path.exists(env_godot) and (not os.name == "nt" or env_godot.lower().endswith(".exe")):
            return os.path.abspath(env_godot)
        if os.path.exists(env_godot + ".exe"):
            return os.path.abspath(env_godot + ".exe")

    # Try PATH
    godot_path = shutil.which("godot")
    if godot_path:
        real_path = os.path.realpath(godot_path)
        if os.name != "nt" or real_path.lower().endswith(".exe"):
            return real_path
        if os.name == "nt" and os.path.exists(real_path + ".exe"):
            return real_path + ".exe"
    
    return "godot"

def run_command(command, description):
    # If the command starts with 'godot', use our helper to find the correct executable
    if command and command[0] == "godot":
        command[0] = get_godot_command()

    print(f"=== {description} ===")
    
    # On Windows, if we have an absolute path, don't use shell=True to avoid cmd.exe extension issues
    use_shell = False
    if os.name == "nt":
        if not os.path.isabs(command[0]):
            use_shell = True
            
    try:
        subprocess.run(command, check=True, text=True, shell=use_shell)
        return True
    except subprocess.CalledProcessError:
        print(f"\nError during {description}!")
        return False
    except FileNotFoundError:
        print(f"\nError: Executable '{command[0]}' not found.")
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
