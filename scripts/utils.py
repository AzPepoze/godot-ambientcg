import subprocess
import urllib.request
import json
import tarfile
import os
import shutil

def run_command(command, description):
    print(f"=== {description} ===")
    use_shell = os.name == "nt"
    try:
        subprocess.run(command, check=True, text=True, shell=use_shell)
        return True
    except subprocess.CalledProcessError:
        print(f"\nError during {description}!")
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
