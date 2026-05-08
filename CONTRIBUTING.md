# Contributing to Godot AmbientCG

First off, thank you for considering contributing to Godot AmbientCG! It's people like you that make the open-source community such an amazing place to learn, inspire, and create.

## How Can I Contribute?

### Reporting Bugs

- **Search for existing issues**: Check if the bug has already been reported.
- **Provide detail**: Include your Godot version, OS, and clear steps to reproduce the issue.
- **Screenshots**: Attach screenshots if they help explain the problem.

### Suggesting Enhancements

- **Explain the "why"**: Describe why this enhancement would be useful to most users.
- **Be specific**: Provide as much detail as possible about how the feature should work.

### Pull Requests

1. **Fork the repository**.
2. **Create a new branch** for your feature or fix.
3. **Follow the code style**: Use the project's formatting and linting tools.
4. **Write tests**: Add unit tests for new functionality.
5. **Submit a PR** with a clear description of your changes.

## Development Setup

This project uses [uv](https://docs.astral.sh/uv/) for Python-based development tasks and [GUT](https://github.com/bitwes/Gut) for Godot unit testing.

### Prerequisites

- [Godot Engine 4.x](https://godotengine.org/)
- [uv](https://docs.astral.sh/uv/)

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/godot-ambientcg.git
   cd godot-ambientcg
   ```

2. Sync dependencies:
   ```bash
   uv sync
   ```

### Development Tasks

We use `uv` to run various development tasks. You can run them using `uv run task <command>`.

| Command | Description |
| :--- | :--- |
| `check` | Runs `format`, `lint`, and `test` in sequence. |
| `format` | Formats all GDScript files using `gdformat`. |
| `lint` | Checks code style using `gdlint`. |
| `test` | Runs unit tests using the Godot editor in headless mode. |
| `clean` | Removes downloaded assets and Godot cache files. |
| `dev` | Launches the project in the Godot editor. |
| `version` | Gets the current Godot version required. |

## Code Style

We follow the standard [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). Please run `uv run task format` before submitting a PR.

## Testing

Unit tests are located in the `tests/unit/` directory. To run tests, use:
```bash
uv run task test
```
Please ensure all tests pass before submitting your changes.
