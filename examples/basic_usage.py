#!/usr/bin/env python3
"""
Basic usage examples for KAYBAMBODLABFX Bot Framework.
Demonstrates how to create and use different types of bots.
"""

import sys
import os

# Add the parent directory to the path so we can import the bot framework
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from bot_framework import BotManager


def main():
    """Run basic usage examples."""
    print("🤖 KAYBAMBODLABFX Bot Framework - Basic Usage Examples")
    print("=" * 60)
    
    # Initialize bot manager
    bot_manager = BotManager()
    
    # Example 1: Problem Solver Bot
    print("\n📋 Example 1: Problem Solver Bot")
    print("-" * 40)
    
    problem_solver_id = bot_manager.create_bot('problem-solver', name='MyProblemSolver')
    problem = "How can I optimize my Python code for better performance?"
    
    solution = bot_manager.run_bot(problem_solver_id, problem)
    
    print(f"Problem: {solution['problem']}")
    print(f"Solution: {solution['solution']}")
    print(f"Steps: {len(solution['steps'])} action steps")
    print(f"Timeline: {solution['timeline']}")
    print(f"Priority: {solution['priority']}")
    
    # Example 2: Task Automation Bot
    print("\n⚙️ Example 2: Task Automation Bot")
    print("-" * 40)
    
    automation_bot_id = bot_manager.create_bot('task-automation', name='MyAutomator')
    
    # Define a simple task
    task_definition = {
        'name': 'Daily Log Task',
        'type': 'logging',
        'actions': [
            {
                'type': 'log',
                'message': 'Starting daily automation task',
                'level': 'info'
            },
            {
                'type': 'wait',
                'duration': 1
            },
            {
                'type': 'log', 
                'message': 'Task completed successfully',
                'level': 'info'
            }
        ]
    }
    
    result = bot_manager.run_bot(automation_bot_id, task_definition)
    
    print(f"Task: {result['task_name']}")
    print(f"Duration: {result['duration_seconds']:.2f} seconds")
    print(f"Actions executed: {result['actions_executed']}")
    print(f"Success: {result['success']}")
    
    # Example 3: Interactive Bot
    print("\n💬 Example 3: Interactive Bot")
    print("-" * 40)
    
    interactive_bot_id = bot_manager.create_bot('interactive', name='MyAssistant')
    
    # Simulate some interactions
    interactions = [
        "help",
        "status", 
        {"action": "set_context", "data": {"user": "demo", "task": "learning"}},
        "context",
        {"action": "execute_task", "data": {"type": "demo", "message": "Hello World"}}
    ]
    
    for interaction in interactions:
        response = bot_manager.run_bot(interactive_bot_id, interaction)
        
        if isinstance(interaction, str):
            print(f"User: {interaction}")
        else:
            print(f"User: {interaction}")
        
        print(f"Bot: {response['response'][:100]}...")
        print(f"Action: {response['action']}")
        print()
    
    # List all bots
    print("\n📊 Bot Summary")
    print("-" * 40)
    
    bots = bot_manager.list_bots()
    for bot in bots:
        print(f"Bot: {bot['name']} (Type: {bot['type']}, Active: {bot['active']})")
        print(f"  Executions: {bot['execution_count']}")
    
    print(f"\nTotal bots created: {len(bots)}")
    print("\n✅ Examples completed successfully!")


if __name__ == "__main__":
    main()