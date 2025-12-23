# KAYBAMBODLABFX Bot Framework

🤖 **A comprehensive bot framework for problem solving and bot creation**

KAYBAMBODLABFX is a powerful, extensible Python framework that enables users to build applications that solve problems and create various types of bots. The framework provides a modular architecture with built-in bot types for common use cases while allowing for easy customization and extension.

## 🚀 Features

- **Problem Solver Bot**: Analyzes problems and provides structured solutions with action steps, resources, and timelines
- **Task Automation Bot**: Automates repetitive tasks and workflows with scheduling capabilities
- **Interactive Bot**: Template for creating custom interactive bots with conversation management
- **Modular Architecture**: Extensible plugin system for adding new bot types
- **Configuration Management**: Flexible configuration system with JSON-based settings
- **Comprehensive Logging**: Built-in logging utilities for debugging and monitoring
- **CLI Interface**: Easy-to-use command-line interface for bot management
- **No External Dependencies**: Uses only Python standard library for maximum compatibility

## 📦 Installation

### Quick Start

```bash
# Clone the repository
git clone https://github.com/jetloo66-dot/KAYBAMBODLABFX.git
cd KAYBAMBODLABFX

# Run directly with Python
python3 main.py --help
```

### Installation via setup.py

```bash
# Install the framework
python3 setup.py install

# Or install in development mode
python3 setup.py develop

# Use the installed command
kaybambodlabfx --help
```

### Optional Dependencies

For enhanced functionality, install optional dependencies:

```bash
# Install full feature set
pip install -e .[full]

# Or install specific feature sets
pip install -e .[web,scheduling,cli]
```

## 🎯 Quick Usage

### Command Line Interface

```bash
# Solve a problem quickly
python3 main.py --solve-problem "How to optimize database performance?"

# Create a new bot
python3 main.py --create-bot problem-solver

# List all bots
python3 main.py --list-bots

# Run interactive mode
python3 main.py
```

### Python API

```python
from bot_framework import BotManager

# Initialize bot manager
bot_manager = BotManager()

# Create a problem solver bot
bot_id = bot_manager.create_bot('problem-solver', name='MyProblemSolver')

# Solve a problem
solution = bot_manager.run_bot(bot_id, "How to improve team productivity?")

print(f"Solution: {solution['solution']}")
print(f"Steps: {len(solution['steps'])} action steps")
print(f"Timeline: {solution['timeline']}")
```

## 🤖 Bot Types

### 1. Problem Solver Bot

Analyzes problems using multiple strategies and provides comprehensive solutions:

```python
# Create and use a problem solver bot
bot_id = bot_manager.create_bot('problem-solver')
solution = bot_manager.run_bot(bot_id, "My application is running slowly")

# Solution includes:
# - Problem analysis (type, complexity, urgency)
# - Structured solution approach
# - Step-by-step action plan
# - Required resources
# - Timeline estimation
# - Success criteria
```

**Features:**
- Automatic problem categorization (technical, business, educational, organizational)
- Multiple solution strategies (breakdown, systematic analysis, resource identification)
- Complexity and urgency assessment
- Keyword extraction and analysis

### 2. Task Automation Bot

Automates repetitive tasks with support for scheduling and workflows:

```python
# Create automation bot
bot_id = bot_manager.create_bot('task-automation')

# Define a task
task = {
    'name': 'Daily Backup',
    'actions': [
        {'type': 'log', 'message': 'Starting backup'},
        {'type': 'file_operation', 'operation': 'read', 'file_path': 'data.txt'},
        {'type': 'wait', 'duration': 2},
        {'type': 'log', 'message': 'Backup completed'}
    ]
}

# Run the task
result = bot_manager.run_bot(bot_id, task)
```

**Supported Actions:**
- `wait`: Pause execution for specified duration
- `log`: Output log messages with different levels
- `file_operation`: Read/write files safely
- `data_processing`: Filter and transform data
- `system_command`: Execute safe system commands

### 3. Interactive Bot

Template for creating custom interactive bots with conversation management:

```python
# Create interactive bot
bot_id = bot_manager.create_bot('interactive')

# Interact with commands
response = bot_manager.run_bot(bot_id, "help")
print(response['response'])

# Use structured input
structured_input = {
    'action': 'set_context',
    'data': {'user': 'john', 'session': 'demo'}
}
response = bot_manager.run_bot(bot_id, structured_input)
```

**Built-in Commands:**
- `help`: Show available commands
- `status`: Display bot status and information
- `history`: Show conversation history
- `context`: Display/manage bot context
- `reset`: Reset bot state

## 📁 Project Structure

```
KAYBAMBODLABFX/
├── main.py                 # Main application entry point
├── bot_framework/          # Core framework package
│   ├── __init__.py
│   ├── core/              # Core framework components
│   │   ├── base_bot.py    # Base bot class
│   │   ├── bot_manager.py # Bot management
│   │   └── bot_registry.py # Bot registration
│   ├── bots/              # Built-in bot implementations
│   │   ├── problem_solver_bot.py
│   │   ├── task_automation_bot.py
│   │   └── interactive_bot.py
│   └── utils/             # Utility modules
│       ├── logger.py      # Logging utilities
│       └── config.py      # Configuration management
├── examples/              # Example scripts
├── config.json           # Configuration file
├── requirements.txt      # Dependencies
├── setup.py             # Installation script
└── README.md           # This file
```

## ⚙️ Configuration

The framework uses a JSON configuration file (`config.json`) for customization:

```json
{
  "bot_framework": {
    "registry_file": "bot_registry.json",
    "log_level": "INFO",
    "max_concurrent_bots": 10,
    "default_bot_timeout": 300
  },
  "problem_solver": {
    "max_analysis_depth": 5,
    "enable_advanced_strategies": true
  },
  "task_automation": {
    "max_concurrent_tasks": 5,
    "task_timeout": 600,
    "safe_mode": true
  }
}
```

## 🧪 Examples

Run the included examples to see the framework in action:

```bash
# Basic usage examples
python3 examples/basic_usage.py

# Problem solving demonstration
python3 examples/problem_solving_demo.py
```

## 🔧 Extending the Framework

### Creating Custom Bot Types

```python
from bot_framework.core import BaseBot

class CustomBot(BaseBot):
    def execute(self, *args, **kwargs):
        # Implement your bot logic here
        return {"result": "Custom bot executed"}

# Register the bot type
bot_manager.registry.register_bot_type('custom', CustomBot)
```

### Adding Custom Commands to Interactive Bots

```python
def custom_command_handler(args):
    return {
        'response': f'Custom command executed with args: {args}',
        'action': 'custom_executed',
        'context': {},
        'suggestions': []
    }

# Register custom command
interactive_bot.register_command('mycmd', custom_command_handler)
```

## 🧪 Testing

The framework includes built-in testing capabilities:

```bash
# Test basic functionality
python3 -c "from bot_framework import BotManager; print('✅ Framework loads successfully')"

# Run example with error handling
python3 main.py --solve-problem "Test problem" --verbose
```

## 📚 API Reference

### BotManager Class

- `create_bot(bot_type, name=None, config=None)`: Create a new bot instance
- `run_bot(identifier, *args, **kwargs)`: Execute a bot
- `list_bots()`: Get list of all bots
- `get_bot(identifier)`: Get bot by ID or name
- `get_or_create_bot(bot_type, name=None)`: Get existing or create new bot

### BaseBot Class

- `execute(*args, **kwargs)`: Abstract method for bot logic
- `activate()` / `deactivate()`: Control bot status
- `get_info()`: Get bot metadata
- `run(*args, **kwargs)`: Execute with tracking

## 🤝 Contributing

Contributions are welcome! Areas for contribution:

1. **New Bot Types**: Implement specialized bots for specific domains
2. **Enhanced Problem Solving**: Improve analysis algorithms and strategies
3. **Task Automation**: Add more action types and scheduling features
4. **Plugin System**: Develop plugin architecture for third-party extensions
5. **Documentation**: Improve examples and documentation

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

## 🛠️ Development Status

- ✅ Core framework architecture
- ✅ Problem solver bot with multiple strategies
- ✅ Task automation bot with basic actions
- ✅ Interactive bot template
- ✅ CLI interface and configuration management
- 🔄 Plugin system (planned)
- 🔄 Web interface (planned)
- 🔄 Advanced scheduling (planned)

## 📞 Support

For questions, issues, or contributions:

- **Issues**: [GitHub Issues](https://github.com/jetloo66-dot/KAYBAMBODLABFX/issues)
- **Documentation**: [Project Wiki](https://github.com/jetloo66-dot/KAYBAMBODLABFX/wiki)
- **Source Code**: [GitHub Repository](https://github.com/jetloo66-dot/KAYBAMBODLABFX)

---

**KAYBAMBODLABFX** - Building intelligent solutions, one bot at a time! 🤖✨
