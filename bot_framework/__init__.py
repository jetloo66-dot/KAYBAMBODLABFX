"""
KAYBAMBODLABFX Bot Framework
A comprehensive framework for creating and managing problem-solving bots.
"""

__version__ = "1.0.0"
__author__ = "KAYBAMBODLABFX Team"

from .core import BotManager, BotRegistry, BaseBot
from .bots import ProblemSolverBot, TaskAutomationBot, InteractiveBot

__all__ = [
    'BotManager',
    'BotRegistry', 
    'BaseBot',
    'ProblemSolverBot',
    'TaskAutomationBot',
    'InteractiveBot'
]