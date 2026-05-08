# Godot AmbientCG

Search, download, and automatically import PBR materials and HDRI environments directly from [ambientCG.com](https://ambientcg.com) into the Godot Engine.

> [!NOTE]
> This project was forked from [VenitStudios/AmbientCG](https://github.com/VenitStudios/AmbientCG).

## Screenshots

<p align="center">
  <img width="515" alt="editor_screenshot" src="https://github.com/user-attachments/assets/dae775b1-250c-4b4a-9127-b34e7570f7eb" />
  <img width="515" alt="material_import" src="https://github.com/user-attachments/assets/98fe5701-3e4a-4cdf-8d75-9ae8c52ef338" />
</p>

## Features

- **Direct Integration**: Search and download assets within the Godot editor.
- **Automatic Import**: Automatically creates Materials and HDRI Environments.
- **Configurable**: Define your own paths for downloads and extractions.

## Installation

1. Copy the `addons/ambientcg` folder into your project's `addons/` directory.
2. Enable the plugin in **Project Settings > Plugins**.
3. Access the browser via the **AmbientCG** button at the top of the editor.

## Usage

1. **Open the Browser**: Click the "AmbientCG" button at the top of the Godot editor.
2. **Search Assets**: Use the search bar to find materials or HDRIs by keywords (e.g., "brick", "forest").
3. **Filter**: Filter results by asset type using the dropdown menu.
4. **Download**: Click on an asset to view details and select a resolution/format. Click "Download" to start the process.
5. **Auto-Import**: Once downloaded, the plugin will automatically extract the files, create a `.tres` material or environment resource, and place it in your configured directories.

## Configuration

You can customize the plugin's behavior in **Project Settings** under the `ambientcg/` section:

| Setting | Default Value | Description |
| :--- | :--- | :--- |
| `ambientcg/extract_path` | `res://ambientcg/extracted` | Where raw asset files are extracted. |
| `ambientcg/material_file_directory` | `res://ambientcg/materials` | Where generated Material resources are saved. |
| `ambientcg/environment_file_directory` | `res://ambientcg/environments` | Where generated Environment resources are saved. |
| `ambientcg/download_path` | `res://ambientcg/temp` | Temporary directory for ZIP downloads. |

## Project Structure

- `addons/ambientcg/core/`: Core logic including API communication, configuration, and parsing.
- `addons/ambientcg/handlers/`: Logic for handling file operations and resource creation (Materials/Environments).
- `addons/ambientcg/ui/`: UI components for the asset browser and detail views.
- `addons/ambientcg/resources/`: Themes, icons, and other static assets.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to set up the development environment and submit pull requests.

### Developer Notes

- Substance Painter Materials are ignored by the material browser.
- Several paths can be changed in Project Settings under `ambientcg/`.

## License

Distributed under the MIT License. See `LICENSE` for more information.

