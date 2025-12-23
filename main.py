#!/usr/bin/env python3
"""
KAYBAMBODLABFX - Bot Framework for Problem Solving and Bot Creation
Main application entry point for the bot framework.
"""

import sys
import json
import argparse
from typing import Dict, List, Any
from bot_framework.core import BotManager, BotRegistry
from bot_framework.bots import ProblemSolverBot, TaskAutomationBot
from bot_framework.utils.logger import setup_logger


def main():
    """Main application entry point."""
    parser = argparse.ArgumentParser(
        description="KAYBAMBODLABFX - Bot Framework for Problem Solving and Bot Creation"
    )
    parser.add_argument(
        "--create-bot", 
        type=str, 
        choices=['problem-solver', 'task-automation', 'interactive'],
        help="Create a new bot of specified type"
    )
    parser.add_argument(
        "--run-bot", 
        type=str, 
        help="Run a bot by name or ID"
    )
    parser.add_argument(
        "--list-bots", 
        action="store_true",
        help="List all available bots"
    )
    parser.add_argument(
        "--solve-problem", 
        type=str, 
        help="Use problem solver bot to solve a specific problem"
    )
    parser.add_argument(
        "--config", 
        type=str, 
        default="config.json",
        help="Configuration file path"
    )
    parser.add_argument(
        "--verbose", 
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    # Setup logging
    logger = setup_logger(verbose=args.verbose)
    logger.info("Starting KAYBAMBODLABFX Bot Framework")
    
    # Initialize bot manager
    bot_manager = BotManager(config_file=args.config)
    
    try:
        if args.create_bot:
            create_bot(bot_manager, args.create_bot, logger)
        elif args.run_bot:
            run_bot(bot_manager, args.run_bot, logger)
        elif args.list_bots:
            list_bots(bot_manager, logger)
        elif args.solve_problem:
            solve_problem(bot_manager, args.solve_problem, logger)
        else:
            # Interactive mode
            interactive_mode(bot_manager, logger)
            
    except KeyboardInterrupt:
        logger.info("Application interrupted by user")
    except Exception as e:
        logger.error(f"Application error: {e}")
        sys.exit(1)


def create_bot(bot_manager: BotManager, bot_type: str, logger) -> None:
    """Create a new bot of the specified type."""
    bot_id = bot_manager.create_bot(bot_type)
    logger.info(f"Created {bot_type} bot with ID: {bot_id}")
    print(f"✅ Successfully created {bot_type} bot with ID: {bot_id}")


def run_bot(bot_manager: BotManager, bot_identifier: str, logger) -> None:
    """Run a specific bot."""
    result = bot_manager.run_bot(bot_identifier)
    logger.info(f"Bot {bot_identifier} execution completed")
    print(f"🤖 Bot execution result: {result}")


def list_bots(bot_manager: BotManager, logger) -> None:
    """List all available bots."""
    bots = bot_manager.list_bots()
    logger.info(f"Found {len(bots)} bots")
    
    if not bots:
        print("No bots found. Create a bot first using --create-bot")
        return
        
    print("\n📋 Available Bots:")
    print("-" * 50)
    for bot in bots:
        status = "🟢 Active" if bot.get('active', False) else "🔴 Inactive"
        print(f"ID: {bot['id']}")
        print(f"Type: {bot['type']}")
        print(f"Name: {bot.get('name', 'Unnamed')}")
        print(f"Status: {status}")
        print(f"Created: {bot.get('created_at', 'Unknown')}")
        print("-" * 50)


def solve_problem(bot_manager: BotManager, problem: str, logger) -> None:
    """Use problem solver bot to solve a specific problem."""
    logger.info(f"Solving problem: {problem}")
    
    # Get or create a problem solver bot
    problem_solver = bot_manager.get_or_create_bot('problem-solver')
    solution = problem_solver.solve(problem)
    
    print(f"\n🧠 Problem: {problem}")
    print(f"💡 Solution: {solution}")


def interactive_mode(bot_manager: BotManager, logger) -> None:
    """Run the application in interactive mode."""
    print("\n🤖 Welcome to KAYBAMBODLABFX Bot Framework!")
    print("Type 'help' for available commands or 'quit' to exit.")
    
    while True:
        try:
            command = input("\n> ").strip().lower()
            
            if command == 'quit' or command == 'exit':
                break
            elif command == 'help':
                show_help()
            elif command == 'list':
                list_bots(bot_manager, logger)
            elif command.startswith('create '):
                bot_type = command.split(' ', 1)[1]
                if bot_type in ['problem-solver', 'task-automation', 'interactive']:
                    create_bot(bot_manager, bot_type, logger)
                else:
                    print("❌ Invalid bot type. Available: problem-solver, task-automation, interactive")
            elif command.startswith('solve '):
                problem = command.split(' ', 1)[1]
                solve_problem(bot_manager, problem, logger)
            elif command.startswith('run '):
                bot_id = command.split(' ', 1)[1]
                run_bot(bot_manager, bot_id, logger)
            else:
                print("❌ Unknown command. Type 'help' for available commands.")
                
        except EOFError:
            break
        except Exception as e:
            logger.error(f"Interactive mode error: {e}")
            print(f"❌ Error: {e}")
    
    print("\n👋 Thank you for using KAYBAMBODLABFX Bot Framework!")


def show_help():
    """Display help information."""
    help_text = """
📚 Available Commands:
- help          : Show this help message
- list          : List all available bots
- create <type> : Create a new bot (problem-solver, task-automation, interactive)
- solve <text>  : Solve a problem using problem solver bot
- run <bot_id>  : Run a specific bot by ID
- quit/exit     : Exit the application

🎯 Bot Types:
- problem-solver   : Analyzes and provides solutions to problems
- task-automation  : Automates repetitive tasks
- interactive      : Template for custom interactive bots

💡 Examples:
> create problem-solver
> solve "How to optimize database queries"
> list
> run bot_123
"""
    print(help_text)


if __name__ == "__main__":
    main()