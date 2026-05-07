# Godot AmbientCG Integration Plugin

Built for Godot 4.4+. This plugin allows you to search, download, and automatically import PBR materials and HDRI environments directly from ambientCG.com into the Godot Engine.

## Features

### Easy to Search and Download PBR Surfaces and HDRI Environments

<img width="515" height="345" alt="editor_screenshot_2026-01-10T162710" src="https://github.com/user-attachments/assets/dae775b1-250c-4b4a-9127-b34e7570f7eb" />

### Download from AmbientCG.com and automatically populate Materials + Environments

<img width="515" height="345" alt="image" src="https://github.com/user-attachments/assets/98fe5701-3e4a-4cdf-8d75-9ae8c52ef338" />

## Installation

1. Copy the `addons/ambientcg` folder into your project's `addons/` directory.
2. Enable the plugin in **Project Settings > Plugins**.
3. Access the browser via the **AmbientCG** button at the top of the editor.

## Development

This repository is set up for cross-platform development and automated testing.

### Prerequisites

- [Godot 4.4+](https://godotengine.org)
- [uv](https://docs.astral.sh/uv/)

### Running Tasks

We use `taskipy` to manage development tasks.

To run linting and unit tests:
```bash
uv run task check
```

To wipe downloaded materials and Godot cache:
```bash
uv run task clean
```

## Developer Notes

- Substance Painter Materials are ignored by the material browser.
- Several Paths can be changed in Project Settings under `ambientcg/`.

## License

This project is licensed under the CC0 1.0 Universal License. See the [LICENSE](LICENSE) file for details.
