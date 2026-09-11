#!/usr/bin/env python3
# Test script for SystemAgent

from ai_agent import SystemAgent

def test_agent():
    agent = SystemAgent()
    
    print("=== Testing SystemAgent ===\n")
    
    # Test 1: Get system info
    print("Test 1: Getting system information...")
    result = agent.get_system_info()
    if result['success']:
        info = result['info']
        print(f"   Platform: {info['platform']}")
        print(f"   Python: {info['python_version']}")
        print(f"   CPU cores: {info['cpu_count']}")
    else:
        print(f"   Error: {result['error']}")
    print()
    
    # Test 2: Execute a command
    print("Test 2: Executing a command...")
    result = agent.execute_command("whoami")
    if result['success']:
        print(f"   Output: {result['output'].strip()}")
    else:
        print(f"   Error: {result['error']}")
    print()
    
    # Test 3: List directory
    print("Test 3: Listing current directory...")
    result = agent.list_directory()
    if result['success']:
        print(f"   Directory: {result['path']}")
        print(f"   Items: {result['count']}")
        for item in result['items'][:5]:
            print(f"     {'[DIR] ' if item['type'] == 'directory' else '      '}{item['name']}")
    else:
        print(f"   Error: {result['error']}")
    print()
    
    print("=== Tests Complete ===")

if __name__ == "__main__":
    test_agent()