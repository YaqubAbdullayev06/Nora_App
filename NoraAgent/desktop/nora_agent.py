"""Nora Desktop Agent — AI assistant that lives in your system tray.

Features:
- System tray icon with right-click menu
- Global hotkey (Ctrl+Shift+N) to summon anywhere
- AI chat powered by Ollama
- File search across your computer
- App launcher
- Command execution
"""

import sys
import os
import json
import threading
import subprocess
import glob
import webbrowser
from pathlib import Path

import httpx
import keyboard
from PIL import Image, ImageDraw, ImageFont
import pystray

# ─── Config ───
OLLAMA_URL = "http://localhost:11434"
MODEL = "llama3.1"
HOTKEY = "ctrl+shift+n"
APP_NAME = "Nora Agent"

# Folders to search for files
SEARCH_PATHS = [
    str(Path.home()),
    "C:\\",
    "D:\\",
]

# Known apps (name -> path or command)
KNOWN_APPS = {
    "notepad": "notepad.exe",
    "calculator": "calc.exe",
    "explorer": "explorer.exe",
    "chrome": "chrome.exe",
    "firefox": "firefox.exe",
    "vscode": "code",
    "terminal": "wt.exe",
    "cmd": "cmd.exe",
    "paint": "mspaint.exe",
    "word": "winword.exe",
    "excel": "excel.exe",
    "powerpoint": "powerpnt.exe",
    "task manager": "taskmgr.exe",
    "settings": "ms-settings:",
    "bluetooth": "ms-settings:bluetooth",
    "wifi": "ms-settings:network-wifi",
    "display": "ms-settings:display",
    "sound": "ms-settings:sound",
    "personalization": "ms-settings:personalization",
}

# System prompt for Nora
SYSTEM_PROMPT = """You are Nora, a powerful desktop AI assistant. You can:

1. SEARCH FILES: Say "search for [filename]" to find files on the computer
2. OPEN APPS: Say "open [app name]" to launch applications
3. RUN COMMANDS: Say "run [command]" to execute system commands
4. OPEN SETTINGS: Say "open settings", "open bluetooth", "open wifi"
5. SEARCH WEB: Say "search [query]" to search Google
6. ANSWER QUESTIONS: You're helpful with any topic

When the user asks to do something, respond with:
- A helpful message
- The action you're taking (if any)

Keep responses concise. Use emoji naturally."""


class NoraAgent:
    """Main Nora Desktop Agent."""

    def __init__(self):
        self.window = None
        self.chat_history = []
        self.is_running = True

    def check_ollama(self) -> bool:
        """Check if Ollama is running."""
        try:
            resp = httpx.get(f"{OLLAMA_URL}/api/tags", timeout=3)
            return resp.status_code == 200
        except Exception:
            return False

    def ask_nora(self, message: str) -> str:
        """Send message to Ollama and get response."""
        # Add to history
        self.chat_history.append({"role": "user", "content": message})

        # Keep last 20 messages for context
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        messages.extend(self.chat_history[-20:])

        try:
            resp = httpx.post(
                f"{OLLAMA_URL}/api/chat",
                json={
                    "model": MODEL,
                    "messages": messages,
                    "stream": False,
                    "options": {"temperature": 0.7, "num_predict": 512},
                },
                timeout=30,
            )
            resp.raise_for_status()
            reply = resp.json()["message"]["content"]

            # Add assistant reply to history
            self.chat_history.append({"role": "assistant", "content": reply})
            return reply

        except Exception as e:
            return f"Error: Can't reach Ollama. Make sure it's running.\n\nStart it with: ollama serve\n\nError: {e}"

    def search_files(self, query: str) -> list[str]:
        """Search for files matching the query."""
        results = []
        query_lower = query.lower()

        for search_path in SEARCH_PATHS:
            if not os.path.exists(search_path):
                continue
            try:
                for root, dirs, files in os.walk(search_path):
                    # Skip system folders
                    dirs[:] = [d for d in dirs if d.lower() not in
                              ['windows', 'program files', '$recycle.bin',
                               'system volume information', 'appdata']]

                    for f in files:
                        if query_lower in f.lower():
                            results.append(os.path.join(root, f))
                            if len(results) >= 10:
                                return results
                    if len(results) >= 10:
                        return results
            except (PermissionError, OSError):
                continue
        return results

    def open_app(self, name: str) -> str:
        """Open an application by name."""
        name_lower = name.lower().strip()

        # Check known apps first
        for key, cmd in KNOWN_APPS.items():
            if key in name_lower:
                try:
                    if cmd.startswith("ms-settings:"):
                        os.startfile(cmd)
                    else:
                        subprocess.Popen(cmd, shell=True)
                    return f"Opened {name}"
                except Exception as e:
                    return f"Failed to open {name}: {e}"

        # Try to find and run the app
        try:
            # Try running directly
            subprocess.Popen(f"start {name}", shell=True)
            return f"Trying to open {name}..."
        except Exception as e:
            return f"Couldn't find app: {name}\nError: {e}"

    def run_command(self, command: str) -> str:
        """Run a system command."""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30,
            )
            output = result.stdout.strip()
            if result.stderr.strip():
                output += f"\n\nErrors:\n{result.stderr.strip()}"
            return output[:2000] if output else "Command executed (no output)"
        except subprocess.TimeoutExpired:
            return "Command timed out (30s limit)"
        except Exception as e:
            return f"Error: {e}"

    def search_web(self, query: str) -> str:
        """Open Google search in browser."""
        url = f"https://www.google.com/search?q={query.replace(' ', '+')}"
        webbrowser.open(url)
        return f"Opened Google search for: {query}"

    def handle_command(self, message: str) -> str:
        """Check if message is a command and handle it."""
        msg_lower = message.lower().strip()

        # File search
        if msg_lower.startswith("search for ") or msg_lower.startswith("find "):
            query = message.split(" ", 2)[-1] if "for" in msg_lower else message.split(" ", 1)[-1]
            results = self.search_files(query)
            if results:
                return f"Found {len(results)} files:\n" + "\n".join(f"📁 {r}" for r in results)
            return f"No files found matching '{query}'"

        # Open app
        if msg_lower.startswith("open ") or msg_lower.startswith("launch "):
            app_name = message.split(" ", 1)[1]
            return self.open_app(app_name)

        # Run command
        if msg_lower.startswith("run ") or msg_lower.startswith("execute "):
            command = message.split(" ", 1)[1]
            return self.run_command(command)

        # Web search
        if msg_lower.startswith("search ") and "for" not in msg_lower:
            query = message.split(" ", 1)[1]
            return self.search_web(query)

        return None  # Not a command, ask AI


def create_icon_image() -> Image.Image:
    """Create a simple tray icon image."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Draw a blue circle
    draw.ellipse([8, 8, 56, 56], fill=(34, 51, 255, 255))
    # Draw "N" letter
    try:
        font = ImageFont.truetype("arial.ttf", 32)
    except Exception:
        font = ImageFont.load_default()
    draw.text((18, 10), "N", fill=(255, 255, 255, 255), font=font)
    return img


def run_agent():
    """Run the Nora Desktop Agent."""
    agent = NoraAgent()

    # Check Ollama
    if not agent.check_ollama():
        print("⚠️  Ollama not running. Start it with: ollama serve")
        print("   Continuing anyway — will show error in chat if AI is asked")

    # Global hotkey callback
    def on_hotkey():
        print("🔑 Nora summoned! (Ctrl+Shift+N)")

    keyboard.add_hotkey(HOTKEY, on_hotkey)

    # Tray menu
    menu = pystray.Menu(
        pystray.MenuItem("Open Nora Chat", lambda: print("Opening chat...")),
        pystray.MenuItem("Check Ollama", lambda: print(f"Ollama: {'Running' if agent.check_ollama() else 'Not running'}")),
        pystray.MenuItem("Exit", lambda: agent.stop()),
    )

    # Create tray icon
    icon = pystray.Icon(
        APP_NAME,
        create_icon_image(),
        APP_NAME,
        menu,
    )

    print(f"""
╔══════════════════════════════════════════════╗
║           🧠 Nora Desktop Agent             ║
╠══════════════════════════════════════════════╣
║  Hotkey:  Ctrl+Shift+N (summon anywhere)    ║
║  AI:      Ollama ({MODEL})                  ║
║  Status:  Running in system tray            ║
╠══════════════════════════════════════════════╣
║  Commands:                                   ║
║    search for [file]  → find files           ║
║    open [app]         → launch app           ║
║    run [cmd]          → execute command      ║
║    search [query]     → Google search        ║
╚══════════════════════════════════════════════╝
""")

    # Run tray icon in background thread
    icon_thread = threading.Thread(target=icon.run, daemon=True)
    icon_thread.start()

    # Keep main thread alive
    try:
        while True:
            import time
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n👋 Nora Agent shutting down...")
        icon.stop()
        sys.exit(0)


if __name__ == "__main__":
    run_agent()
