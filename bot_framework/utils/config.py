"""Configuration management utilities."""

import json
import os
from typing import Any, Dict, Optional, Union


class ConfigManager:
    """Manager for handling configuration files and settings."""
    
    def __init__(self, config_file: str = 'config.json'):
        """Initialize configuration manager.
        
        Args:
            config_file: Path to configuration file
        """
        self.config_file = config_file
        self._config: Dict[str, Any] = {}
        self.load()
        
    def load(self) -> Dict[str, Any]:
        """Load configuration from file.
        
        Returns:
            Configuration dictionary
        """
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    self._config = json.load(f)
            except Exception as e:
                print(f"Warning: Could not load config file {self.config_file}: {e}")
                self._config = self._get_default_config()
        else:
            self._config = self._get_default_config()
            self.save()  # Create default config file
            
        return self._config
        
    def save(self) -> None:
        """Save configuration to file."""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self._config, f, indent=2)
        except Exception as e:
            print(f"Warning: Could not save config file {self.config_file}: {e}")
            
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value.
        
        Args:
            key: Configuration key (supports dot notation for nested keys)
            default: Default value if key not found
            
        Returns:
            Configuration value or default
        """
        if '.' in key:
            keys = key.split('.')
            value = self._config
            
            for k in keys:
                if isinstance(value, dict) and k in value:
                    value = value[k]
                else:
                    return default
                    
            return value
        else:
            return self._config.get(key, default)
            
    def set(self, key: str, value: Any) -> None:
        """Set configuration value.
        
        Args:
            key: Configuration key (supports dot notation for nested keys)
            value: Value to set
        """
        if '.' in key:
            keys = key.split('.')
            config_ref = self._config
            
            # Navigate to the parent of the target key
            for k in keys[:-1]:
                if k not in config_ref:
                    config_ref[k] = {}
                config_ref = config_ref[k]
                
            # Set the value
            config_ref[keys[-1]] = value
        else:
            self._config[key] = value
            
    def update(self, config_dict: Dict[str, Any]) -> None:
        """Update configuration with dictionary.
        
        Args:
            config_dict: Dictionary of configuration updates
        """
        self._config.update(config_dict)
        
    def get_all(self) -> Dict[str, Any]:
        """Get all configuration.
        
        Returns:
            Complete configuration dictionary
        """
        return self._config.copy()
        
    def _get_default_config(self) -> Dict[str, Any]:
        """Get default configuration.
        
        Returns:
            Default configuration dictionary
        """
        return {
            'bot_framework': {
                'registry_file': 'bot_registry.json',
                'log_level': 'INFO',
                'max_concurrent_bots': 10,
                'default_bot_timeout': 300,
                'enable_plugins': True
            },
            'problem_solver': {
                'max_analysis_depth': 5,
                'enable_advanced_strategies': True,
                'default_complexity': 'medium'
            },
            'task_automation': {
                'max_concurrent_tasks': 5,
                'task_timeout': 600,
                'enable_scheduling': True,
                'safe_mode': True
            },
            'interactive': {
                'max_conversation_history': 100,
                'enable_context_persistence': True,
                'command_timeout': 30
            }
        }