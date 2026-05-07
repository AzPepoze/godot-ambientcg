import subprocess
import urllib.request
import json
import tarfile
import os
import shutil

def run_command(command, description):
    print(f"=== {description} ===")
    try:
        subprocess.run(command, check=True, text=True)
        return True
    except subprocess.CalledProcessError:
        print(f"\nError during {description}!")
        return False

def get_latest_godot_version():
    with urllib.request.urlopen("https://api.github.com/repos/godotengine/godot/releases/latest") as response:
        data = json.loads(response.read().decode())
        return data["tag_name"].replace("-stable", "")

def ensure_gut():
    if os.path.exists("addons/gut"):
        return False
    print("=== Downloading Latest GUT ===")
    with urllib.request.urlopen("https://api.github.com/repos/bitwes/Gut/releases/latest") as response:
        data = json.loads(response.read().decode())
        url = data["tarball_url"]
    file_path, _ = urllib.request.urlretrieve(url)
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
