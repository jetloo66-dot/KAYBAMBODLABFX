"""Base bot class that all bots inherit from."""

from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
from datetime import datetime
import uuid


class BaseBot(ABC):
    """Abstract base class for all bots in the framework."""
    
    def __init__(self, name: Optional[str] = None, config: Optional[Dict[str, Any]] = None):
        """Initialize the base bot.
        
        Args:
            name: Optional name for the bot
            config: Configuration dictionary for the bot
        """
        self.id = str(uuid.uuid4())
        self.name = name or f"{self.__class__.__name__}_{self.id[:8]}"
        self.config = config or {}
        self.created_at = datetime.now()
        self.active = False
        self.execution_count = 0
        self.last_execution = None
        
    @abstractmethod
    def execute(self, *args, **kwargs) -> Any:
        """Execute the bot's main functionality.
        
        This method must be implemented by all bot subclasses.
        
        Returns:
            The result of the bot's execution
        """
        pass
    
    def activate(self) -> None:
        """Activate the bot."""
        self.active = True
        
    def deactivate(self) -> None:
        """Deactivate the bot."""
        self.active = False
        
    def is_active(self) -> bool:
        """Check if the bot is active."""
        return self.active
        
    def get_info(self) -> Dict[str, Any]:
        """Get bot information.
        
        Returns:
            Dictionary containing bot information
        """
        return {
            'id': self.id,
            'name': self.name,
            'type': self.__class__.__name__,
            'active': self.active,
            'created_at': self.created_at.isoformat(),
            'execution_count': self.execution_count,
            'last_execution': self.last_execution.isoformat() if self.last_execution else None,
            'config': self.config
        }
        
    def update_config(self, config: Dict[str, Any]) -> None:
        """Update bot configuration.
        
        Args:
            config: New configuration dictionary
        """
        self.config.update(config)
        
    def run(self, *args, **kwargs) -> Any:
        """Run the bot with execution tracking.
        
        Returns:
            The result of the bot's execution
        """
        if not self.active:
            raise RuntimeError(f"Bot {self.name} is not active")
            
        self.execution_count += 1
        self.last_execution = datetime.now()
        
        try:
            result = self.execute(*args, **kwargs)
            return result
        except Exception as e:
            raise RuntimeError(f"Bot execution failed: {e}") from e
            
    def __str__(self) -> str:
        """String representation of the bot."""
        return f"{self.__class__.__name__}(id={self.id[:8]}, name={self.name}, active={self.active})"
        
    def __repr__(self) -> str:
        """Detailed string representation of the bot."""
        return (f"{self.__class__.__name__}(id='{self.id}', name='{self.name}', "
                f"active={self.active}, executions={self.execution_count})")