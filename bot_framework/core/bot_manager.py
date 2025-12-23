"""Bot manager for orchestrating bot operations."""

from typing import Dict, List, Any, Optional
import json
import os
from .bot_registry import BotRegistry
from .base_bot import BaseBot


class BotManager:
    """Manager for coordinating bot operations and lifecycle."""
    
    def __init__(self, config_file: str = "config.json"):
        """Initialize the bot manager.
        
        Args:
            config_file: Configuration file path
        """
        self.config_file = config_file
        self.config = self._load_config()
        self.registry = BotRegistry(
            storage_file=self.config.get('registry_file', 'bot_registry.json')
        )
        
        # Register built-in bot types
        self._register_builtin_bots()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from file.
        
        Returns:
            Configuration dictionary
        """
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Warning: Could not load config file: {e}")
                
        # Default configuration
        return {
            'registry_file': 'bot_registry.json',
            'log_level': 'INFO',
            'max_concurrent_bots': 10,
            'default_bot_timeout': 300,
            'enable_plugins': True
        }
        
    def _register_builtin_bots(self) -> None:
        """Register built-in bot types."""
        try:
            from ..bots import ProblemSolverBot, TaskAutomationBot, InteractiveBot
            
            self.registry.register_bot_type('problem-solver', ProblemSolverBot)
            self.registry.register_bot_type('task-automation', TaskAutomationBot)
            self.registry.register_bot_type('interactive', InteractiveBot)
            
        except ImportError as e:
            print(f"Warning: Could not import built-in bots: {e}")
            
    def create_bot(self, bot_type: str, name: Optional[str] = None, 
                   config: Optional[Dict[str, Any]] = None) -> str:
        """Create a new bot.
        
        Args:
            bot_type: Type of bot to create
            name: Optional name for the bot
            config: Optional configuration for the bot
            
        Returns:
            Bot ID
        """
        bot = self.registry.create_bot(bot_type, name, config)
        bot.activate()  # Activate by default
        return bot.id
        
    def get_bot(self, identifier: str) -> Optional[BaseBot]:
        """Get a bot by ID or name.
        
        Args:
            identifier: Bot ID or name
            
        Returns:
            Bot instance or None if not found
        """
        # Try by ID first
        bot = self.registry.get_bot(identifier)
        if bot:
            return bot
            
        # Try by name
        return self.registry.get_bot_by_name(identifier)
        
    def run_bot(self, identifier: str, *args, **kwargs) -> Any:
        """Run a specific bot.
        
        Args:
            identifier: Bot ID or name
            *args: Arguments to pass to bot
            **kwargs: Keyword arguments to pass to bot
            
        Returns:
            Bot execution result
            
        Raises:
            ValueError: If bot is not found
        """
        bot = self.get_bot(identifier)
        if not bot:
            raise ValueError(f"Bot not found: {identifier}")
            
        return bot.run(*args, **kwargs)
        
    def list_bots(self) -> List[Dict[str, Any]]:
        """List all bots with their information.
        
        Returns:
            List of bot information dictionaries
        """
        return [bot.get_info() for bot in self.registry.list_bots()]
        
    def get_or_create_bot(self, bot_type: str, name: Optional[str] = None) -> BaseBot:
        """Get an existing bot of type or create a new one.
        
        Args:
            bot_type: Type of bot
            name: Optional specific name to look for
            
        Returns:
            Bot instance
        """
        # Look for existing bot of this type
        existing_bots = self.registry.get_bots_by_type(bot_type)
        
        if name:
            # Look for specific named bot
            for bot in existing_bots:
                if bot.name == name:
                    return bot
        elif existing_bots:
            # Return first available bot of this type
            return existing_bots[0]
            
        # Create new bot
        bot_id = self.create_bot(bot_type, name)
        return self.get_bot(bot_id)
        
    def activate_bot(self, identifier: str) -> bool:
        """Activate a bot.
        
        Args:
            identifier: Bot ID or name
            
        Returns:
            True if successful, False if bot not found
        """
        bot = self.get_bot(identifier)
        if bot:
            bot.activate()
            return True
        return False
        
    def deactivate_bot(self, identifier: str) -> bool:
        """Deactivate a bot.
        
        Args:
            identifier: Bot ID or name
            
        Returns:
            True if successful, False if bot not found
        """
        bot = self.get_bot(identifier)
        if bot:
            bot.deactivate()
            return True
        return False
        
    def remove_bot(self, identifier: str) -> bool:
        """Remove a bot.
        
        Args:
            identifier: Bot ID or name
            
        Returns:
            True if successful, False if bot not found
        """
        bot = self.get_bot(identifier)
        if bot:
            return self.registry.remove_bot(bot.id)
        return False
        
    def get_bot_types(self) -> List[str]:
        """Get list of available bot types.
        
        Returns:
            List of bot type identifiers
        """
        return self.registry.list_bot_types()
        
    def shutdown(self) -> None:
        """Shutdown the bot manager and cleanup resources."""
        # Deactivate all bots
        for bot in self.registry.list_bots():
            bot.deactivate()
            
        print("Bot manager shutdown complete")