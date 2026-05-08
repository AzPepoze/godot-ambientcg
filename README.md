# Godot AmbientCG

Search, download, and automatically import PBR materials and HDRI environments directly from ambientCG.com into the Godot Engine.

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

## Development

This project uses [uv](https://docs.astral.sh/uv/) for development task management.

| Task | Command | Description |
| :--- | :--- | :--- |
| **Check** | `uv run task check` | Run all linting and unit tests. |
| **Format** | `uv run task format` | Automatically format GDScript files. |
| **Lint** | `uv run task lint` | Run gdlint to check for code style issues. |
| **Clean** | `uv run task clean` | Wipe downloaded materials and Godot cache. |
| **Dev** | `uv run task dev` | Launch the project in Godot editor. |
| **Version** | `uv run task version` | Get the current Godot version required. |

### Developer Notes

- Substance Painter Materials are ignored by the material browser.
- Several paths can be changed in Project Settings under `ambientcg/`.

