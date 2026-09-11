#!/usr/bin/env python3
"""
Demo script showing System Agent capabilities
"""

import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ai_agent import SystemAgent


def main():
    """Demo the agent's capabilities"""
    print("=== System Agent Demo ===\n")
    
    # Create agent instance
    agent = SystemAgent()
    
    # 1. System Information
    print("1. Getting system information...")
    result = agent.get_system_info()
    if result['success']:
        info = result['info']
        print(f"   Platform: {info['platform']}")
        print(f"   Python: {info['python_version']}")
        print(f"   CPU cores: {info['cpu_count']}")
        print()
    
    # 2. Execute a command
    print("2. Executing a command...")
    result = agent.execute_command("echo 'Hello from System Agent!'")
    if result['success']:
        print(f"   Output: {result['output'].strip()}")
        print()
    
    # 3. List current directory
    print("3. Listing current directory...")
    result = agent.list_directory()
    if result['success']:
        print(f"   Directory: {result['path']}")
        print(f"   Items: {result['count']}")
        for item in result['items'][:5]:  # Show first 5 items
            print(f"     {'[DIR] ' if item['type'] == 'directory' else '      '}{item['name']}")
        if result['count'] > 5:
            print(f"     ... and {result['count'] - 5} more items")
        print()
    
    # 4. File operations
    print("4. Demonstrating file operations...")
    
    # Create a test file
    test_content = "This is a test file created by the System Agent demo."
    result = agent.write_file("demo_test.txt", test_content)
    if result['success']:
        print(f"   Created file: {result['path']}")
    
    # Read the file
    result = agent.read_file("demo_test.txt")
    if result['success']:
        print(f"   Read file content: {result['content'][:50]}...")
    
    # Delete the file
    result = agent.delete_file("demo_test.txt")
    if result['success']:
        print(f"   Deleted file: {result['path']}")
        print()
    
    # 5. Search for files
    print("5. Searching for Python files...")
    result = agent.search_files("*.py")
    if result['success']:
        print(f"   Found {result['count']} Python files")
        for match in result['matches'][:3]:  # Show first 3 matches
            print(f"     {match}")
        print()
    
    print("=== Demo Complete ===")
    print("\nThe agent is ready to use!")
    print("Run 'python ai_agent.py' for interactive mode")
    print("Run 'python ai_agent.py help' for command list")


if __name__ == '__main__':
    main()