#!/usr/bin/env python3
"""
KAYBAMBODLABFX - Main Bot Strategy Program
A FOREX trading bot with configurable strategies
"""

import json
import logging
from datetime import datetime
from typing import Dict, List, Optional
from config import BotConfig
from utils import TradingUtils

class ForexBot:
    """Main FOREX trading bot class"""
    
    def __init__(self, config_file: str = "config.json"):
        """Initialize the bot with configuration"""
        self.config = BotConfig(config_file)
        self.utils = TradingUtils()
        self.positions = []
        self.balance = self.config.initial_balance
        self.setup_logging()
        
    def setup_logging(self):
        """Setup logging configuration"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('bot_strategy.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def analyze_market(self, pair: str) -> Dict:
        """Analyze market conditions for a currency pair"""
        self.logger.info(f"Analyzing market for {pair}")
        
        # Simulate market analysis
        analysis = {
            'pair': pair,
            'trend': self.utils.determine_trend(),
            'volatility': self.utils.calculate_volatility(),
            'support_level': self.utils.get_support_level(),
            'resistance_level': self.utils.get_resistance_level(),
            'signal': 'HOLD'  # Default signal
        }
        
        # Simple strategy logic
        if analysis['trend'] == 'BULLISH' and analysis['volatility'] < 0.5:
            analysis['signal'] = 'BUY'
        elif analysis['trend'] == 'BEARISH' and analysis['volatility'] < 0.5:
            analysis['signal'] = 'SELL'
            
        return analysis
        
    def execute_trade(self, signal: str, pair: str, amount: float) -> bool:
        """Execute a trade based on signal"""
        if self.balance < amount:
            self.logger.warning(f"Insufficient balance for trade: {amount}")
            return False
            
        trade = {
            'timestamp': datetime.now().isoformat(),
            'pair': pair,
            'signal': signal,
            'amount': amount,
            'price': self.utils.get_current_price(pair)
        }
        
        self.positions.append(trade)
        self.balance -= amount
        
        self.logger.info(f"Trade executed: {signal} {amount} {pair} at {trade['price']}")
        return True
        
    def run_strategy(self):
        """Main strategy execution loop"""
        self.logger.info("Starting bot strategy execution")
        
        for pair in self.config.trading_pairs:
            analysis = self.analyze_market(pair)
            
            if analysis['signal'] in ['BUY', 'SELL']:
                trade_amount = self.config.trade_amount
                if self.execute_trade(analysis['signal'], pair, trade_amount):
                    self.logger.info(f"Successfully executed {analysis['signal']} for {pair}")
                    
        self.logger.info(f"Strategy execution complete. Current balance: {self.balance}")
        
    def get_portfolio_status(self) -> Dict:
        """Get current portfolio status"""
        return {
            'balance': self.balance,
            'positions': len(self.positions),
            'total_trades': len(self.positions),
            'last_updated': datetime.now().isoformat()
        }

def main():
    """Main entry point"""
    print("KAYBAMBODLABFX - Bot Strategy Starting...")
    
    try:
        bot = ForexBot()
        bot.run_strategy()
        status = bot.get_portfolio_status()
        print(f"Bot execution completed. Status: {status}")
        
    except Exception as e:
        print(f"Error running bot strategy: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main())