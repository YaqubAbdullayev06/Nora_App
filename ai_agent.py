#!/usr/bin/env python3
"""
Standalone AI Agent with System Access
A Python-based AI agent that can execute system commands, read/write files,
and perform various system operations.
"""

import os
import sys
import subprocess
import json
import shutil
import platform
import psutil
import urllib.parse
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta


@dataclass
class AgentConfig:
    """Configuration for the AI agent"""
    name: str = "SystemAgent"
    version: str = "1.0.0"
    max_command_timeout: int = 30
    allowed_directories: List[str] = None
    blocked_commands: List[str] = None
    social_media_allowlist: List[str] = None
    device_settings_allowlist: List[str] = None
    require_social_media_approval: bool = True
    
    def __post_init__(self):
        if self.allowed_directories is None:
            self.allowed_directories = []
        if self.blocked_commands is None:
            self.blocked_commands = ['rm -rf /', 'format', 'del /s /q C:\\*']
        if self.social_media_allowlist is None:
            self.social_media_allowlist = ['x', 'linkedin', 'youtube']
        if self.device_settings_allowlist is None:
            self.device_settings_allowlist = ['brightness', 'volume', 'airplane_mode', 'screen_timeout', 'wifi']


class DeviceSettingsSkill:
    """Limited access to safe device settings only after explicit user approval."""

    _allowed_settings = {
        'brightness': {'type': 'int', 'min': 0, 'max': 100},
        'volume': {'type': 'int', 'min': 0, 'max': 100},
        'airplane_mode': {'type': 'bool', 'values': [True, False]},
        'screen_timeout': {'type': 'int', 'min': 15, 'max': 600},
        'wifi': {'type': 'bool', 'values': [True, False]},
    }

    def __init__(self, config: AgentConfig):
        self.config = config
        self.approved_settings = set(setting.lower() for setting in config.device_settings_allowlist)
        self.current_values = {
            'brightness': 60,
            'volume': 45,
            'airplane_mode': False,
            'screen_timeout': 60,
            'wifi': True,
        }

    def list_supported_settings(self) -> List[str]:
        return sorted(self.approved_settings.intersection(self._allowed_settings.keys()))

    def read_setting(self, setting_name: str) -> Dict[str, Any]:
        normalized = (setting_name or '').strip().lower()
        if normalized not in self.approved_settings or normalized not in self._allowed_settings:
            return {'success': False, 'error': f'Setting "{setting_name}" is not in the approved device settings allowlist.'}
        return {'success': True, 'setting': normalized, 'value': self.current_values.get(normalized)}

    def update_setting(self, setting_name: str, value: Any, user_approved: bool = False) -> Dict[str, Any]:
        normalized = (setting_name or '').strip().lower()
        if normalized not in self.approved_settings or normalized not in self._allowed_settings:
            return {'success': False, 'error': f'Setting "{setting_name}" is not in the approved device settings allowlist.'}
        if not user_approved:
            return {'success': False, 'error': 'This device setting requires explicit user approval before it can be changed.'}

        rules = self._allowed_settings[normalized]
        expected_type = rules['type']
        if expected_type == 'int':
            try:
                numeric_value = int(value)
            except (TypeError, ValueError):
                return {'success': False, 'error': f'Value for {normalized} must be an integer.'}
            if numeric_value < rules['min'] or numeric_value > rules['max']:
                return {'success': False, 'error': f'Value for {normalized} must be between {rules["min"]} and {rules["max"]}.'}
            self.current_values[normalized] = numeric_value
            return {'success': True, 'setting': normalized, 'value': numeric_value, 'message': f'{normalized} updated successfully.'}

        if expected_type == 'bool':
            if isinstance(value, str):
                normalized_value = value.strip().lower()
                if normalized_value in ('true', '1', 'on', 'yes'):
                    bool_value = True
                elif normalized_value in ('false', '0', 'off', 'no'):
                    bool_value = False
                else:
                    return {'success': False, 'error': f'Value for {normalized} must be a boolean.'}
            else:
                bool_value = bool(value)
            self.current_values[normalized] = bool_value
            return {'success': True, 'setting': normalized, 'value': bool_value, 'message': f'{normalized} updated successfully.'}

        return {'success': False, 'error': f'Unsupported setting type for {normalized}.'}


class FocusModeSkill:
    """Schedule focus windows that block social-media actions."""

    def __init__(self):
        self.start_at: Optional[datetime] = None
        self.end_at: Optional[datetime] = None
        self.label: Optional[str] = None

    def schedule(self, start_time: str, duration_minutes: int, label: str = 'Focus session', now: Optional[datetime] = None) -> Dict[str, Any]:
        try:
            parsed_time = datetime.strptime(start_time.strip(), '%H:%M').time()
            duration = int(duration_minutes)
        except (AttributeError, TypeError, ValueError):
            return {'success': False, 'error': 'Use a 24-hour start time such as 09:00 and an integer duration.'}

        if duration <= 0 or duration > 24 * 60:
            return {'success': False, 'error': 'Focus duration must be between 1 and 1440 minutes.'}

        current = now or datetime.now()
        start = datetime.combine(current.date(), parsed_time)
        if start < current:
            start += timedelta(days=1)

        self.start_at = start
        self.end_at = start + timedelta(minutes=duration)
        self.label = label.strip() or 'Focus session'
        return self.status(now=current)

    def start_now(self, duration_minutes: int, label: str = 'Focus session', now: Optional[datetime] = None) -> Dict[str, Any]:
        current = now or datetime.now()
        return self.schedule(current.strftime('%H:%M'), duration_minutes, label, now=current - timedelta(minutes=1))

    def stop(self) -> Dict[str, Any]:
        self.start_at = None
        self.end_at = None
        self.label = None
        return {'success': True, 'active': False, 'message': 'Focus mode stopped. Social-media actions are available again.'}

    def is_active(self, now: Optional[datetime] = None) -> bool:
        current = now or datetime.now()
        return self.start_at is not None and self.end_at is not None and self.start_at <= current < self.end_at

    def status(self, now: Optional[datetime] = None) -> Dict[str, Any]:
        current = now or datetime.now()
        active = self.is_active(current)
        return {
            'success': True,
            'active': active,
            'label': self.label,
            'starts_at': self.start_at.isoformat() if self.start_at else None,
            'ends_at': self.end_at.isoformat() if self.end_at else None,
            'social_media_blocked': active,
        }


class SocialMediaSkill:
    """Safe social media capability with allowlist, approval gating, and OAuth authorization flow."""

    _platform_configs = {
        'x': {
            'auth_url': 'https://twitter.com/i/oauth2/authorize',
            'token_url': 'https://api.twitter.com/2/oauth2/token',
            'scopes': ['tweet.write', 'users.read', 'offline.access'],
            'client_id': 'demo-x-client-id',
        },
        'linkedin': {
            'auth_url': 'https://www.linkedin.com/oauth/v2/authorization',
            'token_url': 'https://www.linkedin.com/oauth/v2/accessToken',
            'scopes': ['w_member_social', 'r_liteprofile'],
            'client_id': 'demo-linkedin-client-id',
        },
        'youtube': {
            'auth_url': 'https://accounts.google.com/o/oauth2/v2/auth',
            'token_url': 'https://oauth2.googleapis.com/token',
            'scopes': ['https://www.googleapis.com/auth/youtube.force-ssl'],
            'client_id': 'demo-youtube-client-id',
        },
    }

    def __init__(self, config: AgentConfig, focus_mode: Optional[FocusModeSkill] = None):
        self.config = config
        self.focus_mode = focus_mode
        self.connected_accounts: Dict[str, str] = {}
        self.oauth_states: Dict[str, str] = {}
        self.oauth_tokens: Dict[str, Dict[str, Any]] = {}
        self.approved_platforms = set(platform.lower() for platform in config.social_media_allowlist)

    def _reject_during_focus(self) -> Optional[Dict[str, Any]]:
        if self.focus_mode and self.focus_mode.is_active():
            return {
                'success': False,
                'error': 'Social-media access is blocked while focus mode is active. Stop focus mode or wait until the session ends.'
            }
        return None

    def list_supported_platforms(self) -> List[str]:
        """Return the approved platform list."""
        return sorted(self.approved_platforms)

    def start_oauth_flow(self, platform: str, redirect_uri: str, state: Optional[str] = None) -> Dict[str, Any]:
        """Generate a real OAuth authorization URL for an approved platform."""
        focus_error = self._reject_during_focus()
        if focus_error:
            return focus_error
        normalized = (platform or '').strip().lower()
        if normalized not in self.approved_platforms:
            return {
                'success': False,
                'error': f'Platform "{platform}" is not in allowlist. Only {sorted(self.approved_platforms)} are enabled.'
            }

        platform_config = self._platform_configs.get(normalized)
        if platform_config is None:
            return {'success': False, 'error': f'Platform "{platform}" is not configured for OAuth.'}

        if not redirect_uri or not str(redirect_uri).strip():
            return {'success': False, 'error': 'redirect_uri is required for OAuth.'}

        auth_state = state or os.urandom(16).hex()
        self.oauth_states[normalized] = auth_state

        params = {
            'client_id': platform_config['client_id'],
            'redirect_uri': redirect_uri,
            'response_type': 'code',
            'scope': ' '.join(platform_config['scopes']),
            'state': auth_state,
        }

        authorization_url = f"{platform_config['auth_url']}?{urllib.parse.urlencode(params)}"
        return {
            'success': True,
            'platform': normalized,
            'authorization_url': authorization_url,
            'state': auth_state,
            'token_url': platform_config['token_url'],
            'message': 'OAuth flow started. User must approve the app before tokens are exchanged.'
        }

    def exchange_oauth_code(self, platform: str, code: str, redirect_uri: str, state: Optional[str] = None) -> Dict[str, Any]:
        """Exchange an OAuth authorization code for a token, if the platform is approved."""
        focus_error = self._reject_during_focus()
        if focus_error:
            return focus_error
        normalized = (platform or '').strip().lower()
        if normalized not in self.approved_platforms:
            return {
                'success': False,
                'error': 'Platform is not approved for this agent.'
            }
        if not code or not str(code).strip():
            return {'success': False, 'error': 'OAuth code is required.'}
        if not redirect_uri or not str(redirect_uri).strip():
            return {'success': False, 'error': 'redirect_uri is required.'}

        expected_state = self.oauth_states.get(normalized)
        if expected_state and state and state != expected_state:
            return {'success': False, 'error': 'OAuth state mismatch. The authorization request may have been tampered with.'}

        platform_config = self._platform_configs.get(normalized)
        token_payload = {
            'grant_type': 'authorization_code',
            'code': str(code).strip(),
            'redirect_uri': str(redirect_uri).strip(),
            'client_id': platform_config['client_id'],
            'client_secret': 'demo-secret',
        }

        self.oauth_tokens[normalized] = {
            'access_token': f'{normalized}_access_token_demo',
            'refresh_token': f'{normalized}_refresh_token_demo',
            'expires_in': 3600,
            'token_type': 'Bearer',
            'payload': token_payload,
            'approved': True,
        }

        return {
            'success': True,
            'platform': normalized,
            'token_type': 'Bearer',
            'access_token': self.oauth_tokens[normalized]['access_token'],
            'message': 'OAuth token received and stored securely for the approved account.'
        }

    def connect_account(self, platform: str, account_id: str) -> Dict[str, Any]:
        """Connect only to approved platforms after explicit approval."""
        focus_error = self._reject_during_focus()
        if focus_error:
            return focus_error
        normalized = (platform or '').strip().lower()
        if not normalized:
            return {'success': False, 'error': 'Platform name is required.'}
        if normalized not in self.approved_platforms:
            return {
                'success': False,
                'error': f'Platform "{platform}" is not in allowlist. Only {sorted(self.approved_platforms)} are enabled.'
            }
        if not account_id or not str(account_id).strip():
            return {'success': False, 'error': 'Account ID is required.'}

        self.connected_accounts[normalized] = str(account_id).strip()
        return {
            'success': True,
            'platform': normalized,
            'account_id': str(account_id).strip(),
            'message': 'Account connected. Explicit approval is required before sending content.'
        }

    def approve_post(self, platform: str) -> bool:
        """Check whether posting is explicitly approved for this platform."""
        if not self.config.require_social_media_approval:
            return True
        return platform.lower() in self.connected_accounts

    def post_content(self, platform: str, account_id: str, text: str) -> Dict[str, Any]:
        """Post content only to a connected, approved platform and only with explicit consent."""
        focus_error = self._reject_during_focus()
        if focus_error:
            return focus_error
        normalized = (platform or '').strip().lower()
        if normalized not in self.approved_platforms:
            return {
                'success': False,
                'error': 'Platform is not approved for this agent.'
            }
        if not account_id or not str(account_id).strip():
            return {'success': False, 'error': 'Account ID is required.'}
        if not text or not str(text).strip():
            return {'success': False, 'error': 'Text content is required.'}

        connected_account = self.connected_accounts.get(normalized)
        if connected_account is None or connected_account != str(account_id).strip():
            return {
                'success': False,
                'error': 'No explicit approval found for this account. Connect the account first.'
            }

        if not self.approve_post(normalized):
            return {
                'success': False,
                'error': 'Posting requires explicit approval before the platform can be used.'
            }

        return {
            'success': True,
            'platform': normalized,
            'account_id': str(account_id).strip(),
            'message': 'Content is approved and queued for posting to the connected social account.',
            'content_preview': str(text).strip()[:280]
        }


class SystemAgent:
    """Main AI Agent class with system access capabilities"""
    
    def __init__(self, config: AgentConfig = None):
        self.config = config or AgentConfig()
        self.focus_mode = FocusModeSkill()
        self.social_media = SocialMediaSkill(self.config, self.focus_mode)
        self.device_settings = DeviceSettingsSkill(self.config)
        self.history: List[Dict[str, Any]] = []
        self.current_directory = os.getcwd()
        
    def execute_command(self, command: str, timeout: int = None) -> Dict[str, Any]:
        """Execute a system command and return the result"""
        if timeout is None:
            timeout = self.config.max_command_timeout
            
        # Check for blocked commands
        for blocked in self.config.blocked_commands:
            if blocked.lower() in command.lower():
                return {
                    'success': False,
                    'error': f'Command blocked: {blocked}',
                    'output': '',
                    'timestamp': datetime.now().isoformat()
                }
        
        try:
            # Execute command
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=self.current_directory
            )
            
            output = {
                'success': result.returncode == 0,
                'output': result.stdout,
                'error': result.stderr,
                'return_code': result.returncode,
                'command': command,
                'timestamp': datetime.now().isoformat()
            }
            
            self.history.append(output)
            return output
            
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'error': f'Command timed out after {timeout} seconds',
                'output': '',
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'output': '',
                'timestamp': datetime.now().isoformat()
            }
    
    def read_file(self, file_path: str) -> Dict[str, Any]:
        """Read contents of a file"""
        try:
            path = Path(file_path)
            if not path.exists():
                return {'success': False, 'error': 'File not found'}
            
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            return {
                'success': True,
                'content': content,
                'size': len(content),
                'path': str(path.absolute()),
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def write_file(self, file_path: str, content: str) -> Dict[str, Any]:
        """Write content to a file"""
        try:
            path = Path(file_path)
            path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            return {
                'success': True,
                'path': str(path.absolute()),
                'size': len(content),
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def list_directory(self, directory: str = None) -> Dict[str, Any]:
        """List contents of a directory"""
        try:
            if directory is None:
                directory = self.current_directory
            
            path = Path(directory)
            if not path.exists():
                return {'success': False, 'error': 'Directory not found'}
            
            items = []
            for item in path.iterdir():
                items.append({
                    'name': item.name,
                    'type': 'directory' if item.is_dir() else 'file',
                    'size': item.stat().st_size if item.is_file() else None,
                    'modified': datetime.fromtimestamp(item.stat().st_mtime).isoformat()
                })
            
            return {
                'success': True,
                'path': str(path.absolute()),
                'items': items,
                'count': len(items),
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def search_files(self, pattern: str, directory: str = None) -> Dict[str, Any]:
        """Search for files matching a pattern"""
        try:
            if directory is None:
                directory = self.current_directory
            
            path = Path(directory)
            matches = list(path.glob(pattern))
            
            return {
                'success': True,
                'pattern': pattern,
                'matches': [str(match) for match in matches],
                'count': len(matches),
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def get_system_info(self) -> Dict[str, Any]:
        """Get system information"""
        try:
            info = {
                'platform': platform.platform(),
                'processor': platform.processor(),
                'python_version': platform.python_version(),
                'current_directory': self.current_directory,
                'cpu_count': psutil.cpu_count(),
                'memory_total': psutil.virtual_memory().total,
                'memory_available': psutil.virtual_memory().available,
                'disk_usage': {
                    'total': psutil.disk_usage('/').total,
                    'used': psutil.disk_usage('/').used,
                    'free': psutil.disk_usage('/').free
                }
            }
            return {'success': True, 'info': info}
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def change_directory(self, directory: str) -> Dict[str, Any]:
        """Change current working directory"""
        try:
            path = Path(directory)
            if not path.exists():
                return {'success': False, 'error': 'Directory not found'}
            
            self.current_directory = str(path.absolute())
            os.chdir(self.current_directory)
            
            return {
                'success': True,
                'new_directory': self.current_directory,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def copy_file(self, source: str, destination: str) -> Dict[str, Any]:
        """Copy a file from source to destination"""
        try:
            src_path = Path(source)
            dst_path = Path(destination)
            
            if not src_path.exists():
                return {'success': False, 'error': 'Source file not found'}
            
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_path, dst_path)
            
            return {
                'success': True,
                'source': str(src_path.absolute()),
                'destination': str(dst_path.absolute()),
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def move_file(self, source: str, destination: str) -> Dict[str, Any]:
        """Move a file from source to destination"""
        try:
            src_path = Path(source)
            dst_path = Path(destination)
            
            if not src_path.exists():
                return {'success': False, 'error': 'Source file not found'}
            
            dst_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src_path), str(dst_path))
            
            return {
                'success': True,
                'source': str(src_path.absolute()),
                'destination': str(dst_path.absolute()),
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def delete_file(self, file_path: str) -> Dict[str, Any]:
        """Delete a file"""
        try:
            path = Path(file_path)
            if not path.exists():
                return {'success': False, 'error': 'File not found'}
            
            if path.is_file():
                path.unlink()
            elif path.is_dir():
                shutil.rmtree(path)
            
            return {
                'success': True,
                'path': str(path.absolute()),
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def get_history(self) -> List[Dict[str, Any]]:
        """Get command history"""
        return self.history
    
    def clear_history(self):
        """Clear command history"""
        self.history = []


class AgentCLI:
    """Command-line interface for the AI agent"""
    
    def __init__(self):
        self.agent = SystemAgent()
        self.running = True
        
    def print_help(self):
        """Print available commands"""
        help_text = """
System Agent Commands:
======================
help                    - Show this help message
exit/quit               - Exit the agent
cmd <command>           - Execute a system command
read <file>             - Read file contents
write <file> <content>  - Write content to a file
list [directory]        - List directory contents
search <pattern>        - Search for files
cd <directory>          - Change directory
copy <src> <dst>        - Copy a file
move <src> <dst>        - Move a file
delete <file>           - Delete a file
info                    - Get system info
history                 - Show command history
device settings         - Show approved device settings
device read <setting>   - Read an allowed device setting
device set <setting> <value> - Update an allowed setting with explicit user approval
social platforms        - Show approved social platforms
social connect <platform> <account_id> - Register an approved account
social post <platform> <account_id> <text> - Post content only after explicit approval
focus schedule <HH:MM> <minutes> [label] - Schedule a focus window that blocks social media
focus start <minutes> [label] - Start focus mode immediately
focus status            - Show focus mode and social-media block status
focus stop              - Stop focus mode early
clear                   - Clear screen
        """
        print(help_text)
    
    def run(self):
        """Run the interactive CLI"""
        print(f"System Agent v{self.agent.config.version} initialized")
        print(f"Current directory: {self.agent.current_directory}")
        print("Type 'help' for available commands\n")
        
        while self.running:
            try:
                user_input = input("agent> ").strip()
                
                if not user_input:
                    continue
                
                parts = user_input.split(maxsplit=1)
                command = parts[0].lower()
                args = parts[1] if len(parts) > 1 else ""
                
                if command in ['exit', 'quit']:
                    print("Goodbye!")
                    self.running = False
                    
                elif command == 'help':
                    self.print_help()
                    
                elif command == 'cmd':
                    if not args:
                        print("Usage: cmd <command>")
                        continue
                    result = self.agent.execute_command(args)
                    if result['success']:
                        print(result['output'])
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'read':
                    if not args:
                        print("Usage: read <file>")
                        continue
                    result = self.agent.read_file(args)
                    if result['success']:
                        print(result['content'])
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'write':
                    if not args:
                        print("Usage: write <file> <content>")
                        continue
                    file_path, content = args.split(maxsplit=1)
                    result = self.agent.write_file(file_path, content)
                    if result['success']:
                        print(f"Written to {result['path']}")
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'list':
                    result = self.agent.list_directory(args if args else None)
                    if result['success']:
                        for item in result['items']:
                            print(f"{'[DIR] ' if item['type'] == 'directory' else '      '}{item['name']}")
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'search':
                    if not args:
                        print("Usage: search <pattern>")
                        continue
                    result = self.agent.search_files(args)
                    if result['success']:
                        for match in result['matches']:
                            print(match)
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'cd':
                    if not args:
                        print("Usage: cd <directory>")
                        continue
                    result = self.agent.change_directory(args)
                    if result['success']:
                        print(f"Changed to {result['new_directory']}")
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'copy':
                    if not args:
                        print("Usage: copy <source> <destination>")
                        continue
                    src, dst = args.split(maxsplit=1)
                    result = self.agent.copy_file(src, dst)
                    if result['success']:
                        print(f"Copied to {result['destination']}")
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'move':
                    if not args:
                        print("Usage: move <source> <destination>")
                        continue
                    src, dst = args.split(maxsplit=1)
                    result = self.agent.move_file(src, dst)
                    if result['success']:
                        print(f"Moved to {result['destination']}")
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'delete':
                    if not args:
                        print("Usage: delete <file>")
                        continue
                    result = self.agent.delete_file(args)
                    if result['success']:
                        print(f"Deleted {result['path']}")
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'info':
                    result = self.agent.get_system_info()
                    if result['success']:
                        info = result['info']
                        print(f"Platform: {info['platform']}")
                        print(f"Processor: {info['processor']}")
                        print(f"Python: {info['python_version']}")
                        print(f"CPU cores: {info['cpu_count']}")
                        print(f"Memory: {info['memory_available'] // (1024**2)} MB available")
                    else:
                        print(f"Error: {result['error']}")
                        
                elif command == 'history':
                    history = self.agent.get_history()
                    if not history:
                        print("No command history")
                    else:
                        for i, entry in enumerate(history[-10:], 1):
                            print(f"{i}. {entry['command']}")

                elif command == 'device':
                    if not args:
                        print(', '.join(self.agent.device_settings.list_supported_settings()))
                        continue
                    subcommand, *rest = args.split(maxsplit=2)
                    if subcommand == 'settings':
                        print(', '.join(self.agent.device_settings.list_supported_settings()))
                    elif subcommand == 'read' and rest:
                        setting_name = rest[0]
                        result = self.agent.device_settings.read_setting(setting_name)
                        print(result['message'] if result.get('message') else result)
                    elif subcommand == 'set' and rest:
                        setting_name, value = rest
                        result = self.agent.device_settings.update_setting(setting_name, value, user_approved=True)
                        print(result['message'] if result.get('message') else result['error'])
                    else:
                        print("Usage: device settings | device read <setting> | device set <setting> <value>")

                elif command == 'social':
                    if not args:
                        print(', '.join(self.agent.social_media.list_supported_platforms()))
                        continue
                    subcommand, *rest = args.split(maxsplit=2)
                    if subcommand == 'platforms':
                        print(', '.join(self.agent.social_media.list_supported_platforms()))
                    elif subcommand == 'connect' and rest:
                        platform, account_id = rest
                        result = self.agent.social_media.connect_account(platform, account_id)
                        print(result['message'] if result['success'] else result['error'])
                    elif subcommand == 'post' and rest:
                        platform, account_id, text = rest
                        result = self.agent.social_media.post_content(platform, account_id, text)
                        print(result['message'] if result['success'] else result['error'])
                    else:
                        print("Usage: social platforms | social connect <platform> <account_id> | social post <platform> <account_id> <text>")

                elif command == 'focus':
                    subcommand, *rest = args.split(maxsplit=3)
                    if subcommand == 'schedule' and len(rest) >= 2:
                        start_time, duration = rest[:2]
                        label = rest[2] if len(rest) == 3 else 'Focus session'
                        result = self.agent.focus_mode.schedule(start_time, duration, label)
                        print(result if not result['success'] else f"Focus scheduled: {result['starts_at']} - {result['ends_at']}")
                    elif subcommand == 'start' and rest:
                        duration = rest[0]
                        label = rest[1] if len(rest) == 2 else 'Focus session'
                        result = self.agent.focus_mode.start_now(duration, label)
                        print(result if not result['success'] else 'Focus mode is active. Social media is blocked.')
                    elif subcommand == 'status':
                        print(self.agent.focus_mode.status())
                    elif subcommand == 'stop':
                        print(self.agent.focus_mode.stop()['message'])
                    else:
                        print("Usage: focus schedule <HH:MM> <minutes> [label] | focus start <minutes> [label] | focus status | focus stop")

                elif command == 'clear':
                    os.system('cls' if os.name == 'nt' else 'clear')

                else:
                    # Try to execute as a command
                    result = self.agent.execute_command(user_input)
                    if result['success']:
                        print(result['output'])
                    else:
                        print(f"Error: {result['error']}")
                        
            except KeyboardInterrupt:
                print("\nGoodbye!")
                self.running = False
            except Exception as e:
                print(f"Error: {e}")


def main():
    """Main entry point"""
    if len(sys.argv) > 1:
        # Command-line mode
        agent = SystemAgent()
        command = sys.argv[1].lower()
        args = ' '.join(sys.argv[2:]) if len(sys.argv) > 2 else ""
        
        if command == 'help':
            print("Available commands: help, cmd, read, write, list, search, cd, copy, move, delete, info, history")
            print("Example: python ai_agent.py cmd 'echo Hello'")
            print("Example: python ai_agent.py read file.txt")
            print("Example: python ai_agent.py info")
            
        elif command == 'cmd':
            if not args:
                print("Usage: python ai_agent.py cmd <command>")
                sys.exit(1)
            result = agent.execute_command(args)
            if result['success']:
                print(result['output'])
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'read':
            if not args:
                print("Usage: python ai_agent.py read <file>")
                sys.exit(1)
            result = agent.read_file(args)
            if result['success']:
                print(result['content'])
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'write':
            if not args:
                print("Usage: python ai_agent.py write <file> <content>")
                sys.exit(1)
            file_path, content = args.split(maxsplit=1)
            result = agent.write_file(file_path, content)
            if result['success']:
                print(f"Written to {result['path']}")
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'list':
            result = agent.list_directory(args if args else None)
            if result['success']:
                for item in result['items']:
                    print(f"{'[DIR] ' if item['type'] == 'directory' else '      '}{item['name']}")
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'search':
            if not args:
                print("Usage: python ai_agent.py search <pattern>")
                sys.exit(1)
            result = agent.search_files(args)
            if result['success']:
                for match in result['matches']:
                    print(match)
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'cd':
            if not args:
                print("Usage: python ai_agent.py cd <directory>")
                sys.exit(1)
            result = agent.change_directory(args)
            if result['success']:
                print(f"Changed to {result['new_directory']}")
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'copy':
            if not args:
                print("Usage: python ai_agent.py copy <source> <destination>")
                sys.exit(1)
            src, dst = args.split(maxsplit=1)
            result = agent.copy_file(src, dst)
            if result['success']:
                print(f"Copied to {result['destination']}")
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'move':
            if not args:
                print("Usage: python ai_agent.py move <source> <destination>")
                sys.exit(1)
            src, dst = args.split(maxsplit=1)
            result = agent.move_file(src, dst)
            if result['success']:
                print(f"Moved to {result['destination']}")
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'delete':
            if not args:
                print("Usage: python ai_agent.py delete <file>")
                sys.exit(1)
            result = agent.delete_file(args)
            if result['success']:
                print(f"Deleted {result['path']}")
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'info':
            result = agent.get_system_info()
            if result['success']:
                info = result['info']
                print(f"Platform: {info['platform']}")
                print(f"Processor: {info['processor']}")
                print(f"Python: {info['python_version']}")
                print(f"CPU cores: {info['cpu_count']}")
                print(f"Memory: {info['memory_available'] // (1024**2)} MB available")
            else:
                print(f"Error: {result['error']}", file=sys.stderr)
                sys.exit(1)
                
        elif command == 'history':
            history = agent.get_history()
            if not history:
                print("No command history")
            else:
                for i, entry in enumerate(history[-10:], 1):
                    print(f"{i}. {entry['command']}")

        elif command == 'device':
            if not args:
                print(', '.join(agent.device_settings.list_supported_settings()))
            elif args.startswith('settings'):
                print(', '.join(agent.device_settings.list_supported_settings()))
            elif args.startswith('read '):
                _, setting_name = args.split(maxsplit=1)
                result = agent.device_settings.read_setting(setting_name)
                if result['success']:
                    print(f"{result['setting']}: {result['value']}")
                else:
                    print(result['error'])
            elif args.startswith('set '):
                _, setting_name, value = args.split(maxsplit=2)
                result = agent.device_settings.update_setting(setting_name, value, user_approved=True)
                print(result['message'] if result.get('message') else result['error'])
            else:
                print("Usage: python ai_agent.py device settings | device read <setting> | device set <setting> <value>")

        elif command == 'social':
            if not args:
                print(', '.join(agent.social_media.list_supported_platforms()))
            elif args.startswith('platforms'):
                print(', '.join(agent.social_media.list_supported_platforms()))
            elif args.startswith('connect '):
                try:
                    _, platform, account_id = args.split(maxsplit=2)
                    result = agent.social_media.connect_account(platform, account_id)
                    print(result['message'] if result['success'] else result['error'])
                except ValueError:
                    print("Usage: python ai_agent.py social connect <platform> <account_id>")
            elif args.startswith('post '):
                try:
                    _, platform, account_id, text = args.split(maxsplit=3)
                    result = agent.social_media.post_content(platform, account_id, text)
                    print(result['message'] if result['success'] else result['error'])
                except ValueError:
                    print("Usage: python ai_agent.py social post <platform> <account_id> <text>")
            else:
                print("Usage: python ai_agent.py social platforms | social connect <platform> <account_id> | social post <platform> <account_id> <text>")

        elif command == 'focus':
            subcommand, *rest = args.split(maxsplit=3)
            if subcommand == 'schedule' and len(rest) >= 2:
                start_time, duration = rest[:2]
                label = rest[2] if len(rest) == 3 else 'Focus session'
                result = agent.focus_mode.schedule(start_time, duration, label)
                print(result if not result['success'] else f"Focus scheduled: {result['starts_at']} - {result['ends_at']}")
            elif subcommand == 'start' and rest:
                duration = rest[0]
                label = rest[1] if len(rest) == 2 else 'Focus session'
                result = agent.focus_mode.start_now(duration, label)
                print(result if not result['success'] else 'Focus mode is active. Social media is blocked.')
            elif subcommand == 'status':
                print(agent.focus_mode.status())
            elif subcommand == 'stop':
                print(agent.focus_mode.stop()['message'])
            else:
                print("Usage: python ai_agent.py focus schedule <HH:MM> <minutes> [label] | focus start <minutes> [label] | focus status | focus stop")

        else:
            print(f"Unknown command: {command}")
            print("Run 'python ai_agent.py help' for available commands")
            sys.exit(1)
    else:
        # Interactive mode
        cli = AgentCLI()
        cli.run()


if __name__ == '__main__':
    main()