"""Bot registry for managing and discovering available bots."""

from typing import Dict, List, Type, Optional, Any
from .base_bot import BaseBot
import json
import os


class BotRegistry:
    """Registry for managing bot types and instances."""
    
    def __init__(self, storage_file: str = "bot_registry.json"):
        """Initialize the bot registry.
        
        Args:
            storage_file: File to persist bot registry data
        """
        self.storage_file = storage_file
        self._bot_types: Dict[str, Type[BaseBot]] = {}
        self._bot_instances: Dict[str, BaseBot] = {}
        self._load_registry()
        
    def register_bot_type(self, bot_type: str, bot_class: Type[BaseBot]) -> None:
        """Register a new bot type.
        
        Args:
            bot_type: String identifier for the bot type
            bot_class: Bot class that inherits from BaseBot
        """
        if not issubclass(bot_class, BaseBot):
            raise ValueError(f"Bot class {bot_class} must inherit from BaseBot")
            
        self._bot_types[bot_type] = bot_class
        
    def get_bot_type(self, bot_type: str) -> Optional[Type[BaseBot]]:
        """Get a registered bot type.
        
        Args:
            bot_type: String identifier for the bot type
            
        Returns:
            Bot class or None if not found
        """
        return self._bot_types.get(bot_type)
        
    def list_bot_types(self) -> List[str]:
        """List all registered bot types.
        
        Returns:
            List of bot type identifiers
        """
        return list(self._bot_types.keys())
        
    def create_bot(self, bot_type: str, name: Optional[str] = None, 
                   config: Optional[Dict[str, Any]] = None) -> BaseBot:
        """Create a new bot instance.
        
        Args:
            bot_type: Type of bot to create
            name: Optional name for the bot
            config: Optional configuration for the bot
            
        Returns:
            New bot instance
            
        Raises:
            ValueError: If bot type is not registered
        """
        bot_class = self.get_bot_type(bot_type)
        if not bot_class:
            raise ValueError(f"Unknown bot type: {bot_type}")
            
        bot = bot_class(name=name, config=config)
        self._bot_instances[bot.id] = bot
        self._save_registry()
        
        return bot
        
    def get_bot(self, bot_id: str) -> Optional[BaseBot]:
        """Get a bot instance by ID.
        
        Args:
            bot_id: Bot identifier
            
        Returns:
            Bot instance or None if not found
        """
        return self._bot_instances.get(bot_id)
        
    def get_bot_by_name(self, name: str) -> Optional[BaseBot]:
        """Get a bot instance by name.
        
        Args:
            name: Bot name
            
        Returns:
            Bot instance or None if not found
        """
        for bot in self._bot_instances.values():
            if bot.name == name:
                return bot
        return None
        
    def list_bots(self) -> List[BaseBot]:
        """List all bot instances.
        
        Returns:
            List of bot instances
        """
        return list(self._bot_instances.values())
        
    def remove_bot(self, bot_id: str) -> bool:
        """Remove a bot instance.
        
        Args:
            bot_id: Bot identifier
            
        Returns:
            True if bot was removed, False if not found
        """
        if bot_id in self._bot_instances:
            del self._bot_instances[bot_id]
            self._save_registry()
            return True
        return False
        
    def get_bots_by_type(self, bot_type: str) -> List[BaseBot]:
        """Get all bots of a specific type.
        
        Args:
            bot_type: Bot type identifier
            
        Returns:
            List of bots of the specified type
        """
        return [bot for bot in self._bot_instances.values() 
                if bot.__class__.__name__.lower().replace('bot', '') == bot_type.replace('-', '')]
                
    def _save_registry(self) -> None:
        """Save registry data to file."""
        try:
            data = {
                'bots': {}
            }
            
            for bot_id, bot in self._bot_instances.items():
                data['bots'][bot_id] = bot.get_info()
                
            with open(self.storage_file, 'w') as f:
                json.dump(data, f, indent=2)
                
        except Exception as e:
            # Log error but don't fail the operation
            print(f"Warning: Could not save registry: {e}")
            
    def _load_registry(self) -> None:
        """Load registry data from file."""
        if not os.path.exists(self.storage_file):
            return
            
        try:
            with open(self.storage_file, 'r') as f:
                data = json.load(f)
                
            # Note: We can't recreate bot instances from JSON without their classes
            # This would require a more sophisticated serialization mechanism
            # For now, we'll just track the metadata
            
        except Exception as e:
            print(f"Warning: Could not load registry: {e}")