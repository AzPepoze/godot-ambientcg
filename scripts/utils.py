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
        
        # On Windows, try to resolve to a .exe
        if os.name == "nt":
            # 1. Try adding .exe if it doesn't have it
            if not env_godot.lower().endswith(".exe"):
                if os.path.exists(env_godot + ".exe"):
                    env_godot = env_godot + ".exe"
            
            # 2. Resolve symlinks
            if os.path.exists(env_godot):
                real_path = os.path.realpath(env_godot)
                # 3. Again, ensure the real path has .exe if it doesn't
                if not real_path.lower().endswith(".exe") and os.path.exists(real_path + ".exe"):
                    real_path = real_path + ".exe"
                
                print(f"Debug: Resolved {env_godot} to {real_path}")
                return real_path

        # If it's a direct path that exists, use it
        if os.path.exists(env_godot):
            return env_godot
        
        # If it's in PATH, use it
        found = shutil.which(env_godot)
        if found:
            return found
        
        print(f"Debug: GODOT env var '{env_godot}' not found on disk or in PATH.")

    # Try the default command
    if shutil.which("godot"):
        return os.path.realpath(shutil.which("godot"))
    
    # On Windows, try common variations and locations if 'godot' isn't found directly
    if os.name == "nt":
        print(f"Debug: Scanning common Windows names.")
        search_names = ["godot.exe", "Godot.exe", "godot4.exe", "Godot4.exe"]
        for name in search_names:
            found = shutil.which(name)
            if found:
                print(f"Debug: Found '{name}' at {found}")
                return os.path.realpath(found)

        # Last ditch effort: check common runner binary paths and installation folders
        user_home = os.path.expanduser("~")
        search_dirs = [
            os.path.join(user_home, "bin"),
            os.path.join(user_home, "godot")
        ]
        
        import glob
        for sdir in search_dirs:
            if not os.path.exists(sdir):
                continue
            
            # Recursive search for anything starting with Godot and ending with .exe
            pattern = os.path.join(sdir, "**", "Godot*.exe")
            matches = glob.glob(pattern, recursive=True)
            
            if matches:
                main_version = [m for m in matches if "_console.exe" not in m.lower()]
                result = main_version[0] if main_version else matches[0]
                real_result = os.path.realpath(result)
                if not real_result.lower().endswith(".exe") and os.path.exists(real_result + ".exe"):
                    real_result = real_result + ".exe"
                print(f"Debug: Found Godot via recursive search: {real_result}")
                return real_result
    
    # Fallback to 'godot'
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
