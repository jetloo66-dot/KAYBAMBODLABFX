#!/usr/bin/env python3
"""
Configuration module for KAYBAMBODLABFX bot
"""

import json
import os
from typing import List, Dict, Any

class BotConfig:
    """Bot configuration management"""
    
    def __init__(self, config_file: str = "config.json"):
        self.config_file = config_file
        self.load_config()
        
    def load_config(self):
        """Load configuration from file or create default"""
        if os.path.exists(self.config_file):
            with open(self.config_file, 'r') as f:
                config_data = json.load(f)
        else:
            config_data = self.get_default_config()
            self.save_config(config_data)
            
        # Set configuration attributes
        self.initial_balance = config_data.get('initial_balance', 10000.0)
        self.trade_amount = config_data.get('trade_amount', 100.0)
        self.trading_pairs = config_data.get('trading_pairs', ['EUR/USD', 'GBP/USD', 'USD/JPY'])
        self.risk_level = config_data.get('risk_level', 'MEDIUM')
        self.max_positions = config_data.get('max_positions', 5)
        self.stop_loss_percent = config_data.get('stop_loss_percent', 2.0)
        self.take_profit_percent = config_data.get('take_profit_percent', 4.0)
        self.strategy_type = config_data.get('strategy_type', 'TREND_FOLLOWING')
        
    def get_default_config(self) -> Dict[str, Any]:
        """Get default configuration"""
        return {
            "initial_balance": 10000.0,
            "trade_amount": 100.0,
            "trading_pairs": [
                "EUR/USD",
                "GBP/USD", 
                "USD/JPY",
                "AUD/USD",
                "USD/CAD"
            ],
            "risk_level": "MEDIUM",
            "max_positions": 5,
            "stop_loss_percent": 2.0,
            "take_profit_percent": 4.0,
            "strategy_type": "TREND_FOLLOWING",
            "timeframe": "1H",
            "indicators": {
                "sma_period": 20,
                "ema_period": 12,
                "rsi_period": 14,
                "rsi_oversold": 30,
                "rsi_overbought": 70
            },
            "trading_hours": {
                "start": "08:00",
                "end": "17:00",
                "timezone": "UTC"
            }
        }
        
    def save_config(self, config_data: Dict[str, Any]):
        """Save configuration to file"""
        with open(self.config_file, 'w') as f:
            json.dump(config_data, f, indent=4)
            
    def update_config(self, updates: Dict[str, Any]):
        """Update configuration with new values"""
        current_config = self.get_current_config()
        current_config.update(updates)
        self.save_config(current_config)
        self.load_config()  # Reload to update instance attributes
        
    def get_current_config(self) -> Dict[str, Any]:
        """Get current configuration as dictionary"""
        return {
            'initial_balance': self.initial_balance,
            'trade_amount': self.trade_amount,
            'trading_pairs': self.trading_pairs,
            'risk_level': self.risk_level,
            'max_positions': self.max_positions,
            'stop_loss_percent': self.stop_loss_percent,
            'take_profit_percent': self.take_profit_percent,
            'strategy_type': self.strategy_type
        }
        
    def validate_config(self) -> bool:
        """Validate configuration parameters"""
        if self.initial_balance <= 0:
            raise ValueError("Initial balance must be positive")
        if self.trade_amount <= 0:
            raise ValueError("Trade amount must be positive")
        if self.trade_amount > self.initial_balance:
            raise ValueError("Trade amount cannot exceed initial balance")
        if not self.trading_pairs:
            raise ValueError("At least one trading pair must be specified")
        if self.risk_level not in ['LOW', 'MEDIUM', 'HIGH']:
            raise ValueError("Risk level must be LOW, MEDIUM, or HIGH")
        return True