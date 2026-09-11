# System Agent Usage Guide

## Overview
This is a standalone AI agent with full system access capabilities. It can execute commands, read/write files, and perform various system operations.

## Installation
1. Install Python 3.7+ if not already installed
2. Install dependencies: `pip install -r requirements.txt`

## Usage Modes

### Interactive Mode
Run the agent without arguments to enter interactive mode:
```bash
python ai_agent.py
```

### Command-Line Mode
Run commands directly from the command line:
```bash
python ai_agent.py <command> [arguments]
```

## Available Commands

### Basic Commands
- `help` - Show available commands
- `info` - Display system information
- `history` - Show command history

### Command Execution
```bash
python ai_agent.py cmd "your command here"
```
Examples:
```bash
python ai_agent.py cmd "dir"
python ai_agent.py cmd "python --version"
python ai_agent.py cmd "git status"
```

### File Operations

#### Read a file
```bash
python ai_agent.py read filename.txt
```

#### Write to a file
```bash
python ai_agent.py write filename.txt "content to write"
```

#### List directory contents
```bash
python ai_agent.py list
python ai_agent.py list /path/to/directory
```

#### Search for files
```bash
python ai_agent.py search "*.py"
python ai_agent.py search "pattern"
```

#### Copy a file
```bash
python ai_agent.py copy source.txt destination.txt
```

#### Move a file
```bash
python ai_agent.py move source.txt destination.txt
```

#### Delete a file
```bash
python ai_agent.py delete filename.txt
```

### Directory Navigation
```bash
python ai_agent.py cd /path/to/directory
```

### Focus Mode
Focus mode blocks all configured social-media OAuth, account connection, and posting actions during the focus window.

Schedule a session for 9:00 AM:
```bash
python ai_agent.py focus schedule 09:00 60 "Deep work"
```

Start immediately, inspect the current status, or stop early:
```bash
python ai_agent.py focus start 60 "Study"
python ai_agent.py focus status
python ai_agent.py focus stop
```

## Interactive Mode Commands
In interactive mode, you can use all the above commands without the `python ai_agent.py` prefix:
```
agent> cmd "echo Hello"
agent> read file.txt
agent> list
agent> info
agent> focus schedule 09:00 60 "Deep work"
agent> focus status
agent> exit
```

## Safety Features
- Blocked dangerous commands (rm -rf /, format, etc.)
- Command timeout protection (30 seconds default)
- Command history tracking

## Configuration
Edit `agent_config.json` to customize:
- Command timeout
- Allowed directories
- Blocked commands
- Feature toggles

## Examples

### Get system information
```bash
python ai_agent.py info
```

### Run a Python script
```bash
python ai_agent.py cmd "python script.py"
```

### Check git status
```bash
python ai_agent.py cmd "git status"
```

### List files in current directory
```bash
python ai_agent.py list
```

### Read a configuration file
```bash
python ai_agent.py read config.json
```

### Create a new file
```bash
python ai_agent.py write new_file.txt "Hello World"
```

## Troubleshooting

### Command not found
Ensure Python is in your system PATH and you're running from the correct directory.

### Permission errors
Some operations may require administrator privileges. Run the terminal as administrator if needed.

### Timeout errors
Long-running commands may timeout. Increase `max_command_timeout` in `agent_config.json` if needed.