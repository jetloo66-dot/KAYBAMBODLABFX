#!/usr/bin/env python3
"""
Utility functions for KAYBAMBODLABFX bot
"""

import random
import math
from typing import List, Dict, Tuple
from datetime import datetime, timedelta

class TradingUtils:
    """Trading utility functions"""
    
    def __init__(self):
        self.price_data = {}
        
    def determine_trend(self) -> str:
        """Determine market trend (simplified simulation)"""
        trends = ['BULLISH', 'BEARISH', 'SIDEWAYS']
        weights = [0.4, 0.4, 0.2]  # Slightly favor trending markets
        return random.choices(trends, weights=weights)[0]
        
    def calculate_volatility(self) -> float:
        """Calculate market volatility (0-1 scale)"""
        return random.uniform(0.1, 0.8)
        
    def get_support_level(self) -> float:
        """Get support level for current analysis"""
        base_price = 1.1000  # EUR/USD example
        return base_price - random.uniform(0.0050, 0.0200)
        
    def get_resistance_level(self) -> float:
        """Get resistance level for current analysis"""
        base_price = 1.1000  # EUR/USD example
        return base_price + random.uniform(0.0050, 0.0200)
        
    def get_current_price(self, pair: str) -> float:
        """Get current price for currency pair (simulated)"""
        # Simplified price simulation
        price_ranges = {
            'EUR/USD': (1.0500, 1.1500),
            'GBP/USD': (1.2000, 1.3500),
            'USD/JPY': (100.00, 150.00),
            'AUD/USD': (0.6500, 0.7500),
            'USD/CAD': (1.2000, 1.4000)
        }
        
        if pair in price_ranges:
            min_price, max_price = price_ranges[pair]
            return round(random.uniform(min_price, max_price), 4)
        else:
            return 1.0000  # Default price
            
    def calculate_sma(self, prices: List[float], period: int) -> float:
        """Calculate Simple Moving Average"""
        if len(prices) < period:
            return sum(prices) / len(prices)
        return sum(prices[-period:]) / period
        
    def calculate_ema(self, prices: List[float], period: int) -> float:
        """Calculate Exponential Moving Average"""
        if not prices:
            return 0.0
            
        if len(prices) == 1:
            return prices[0]
            
        multiplier = 2 / (period + 1)
        ema = prices[0]
        
        for price in prices[1:]:
            ema = (price * multiplier) + (ema * (1 - multiplier))
            
        return ema
        
    def calculate_rsi(self, prices: List[float], period: int = 14) -> float:
        """Calculate Relative Strength Index"""
        if len(prices) < period + 1:
            return 50.0  # Neutral RSI
            
        gains = []
        losses = []
        
        for i in range(1, len(prices)):
            change = prices[i] - prices[i-1]
            if change > 0:
                gains.append(change)
                losses.append(0)
            else:
                gains.append(0)
                losses.append(abs(change))
                
        if len(gains) < period:
            return 50.0
            
        avg_gain = sum(gains[-period:]) / period
        avg_loss = sum(losses[-period:]) / period
        
        if avg_loss == 0:
            return 100.0
            
        rs = avg_gain / avg_loss
        rsi = 100 - (100 / (1 + rs))
        
        return rsi
        
    def calculate_position_size(self, balance: float, risk_percent: float, 
                              stop_loss_distance: float) -> float:
        """Calculate position size based on risk management"""
        risk_amount = balance * (risk_percent / 100)
        if stop_loss_distance <= 0:
            return balance * 0.01  # 1% of balance as fallback
        return risk_amount / stop_loss_distance
        
    def generate_price_data(self, pair: str, days: int = 30) -> List[Dict]:
        """Generate simulated price data for backtesting"""
        data = []
        current_price = self.get_current_price(pair)
        
        for i in range(days):
            # Simple random walk with small bias
            change_percent = random.uniform(-0.02, 0.02)  # ±2% daily change
            current_price *= (1 + change_percent)
            
            data.append({
                'timestamp': (datetime.now() - timedelta(days=days-i)).isoformat(),
                'pair': pair,
                'open': current_price,
                'high': current_price * (1 + random.uniform(0, 0.01)),
                'low': current_price * (1 - random.uniform(0, 0.01)),
                'close': current_price,
                'volume': random.randint(1000, 10000)
            })
            
        return data
        
    def validate_trade_signal(self, signal: str, analysis: Dict) -> bool:
        """Validate if trade signal is reliable"""
        if signal not in ['BUY', 'SELL', 'HOLD']:
            return False
            
        # Simple validation logic
        if signal == 'BUY':
            return analysis.get('trend') == 'BULLISH' and analysis.get('volatility', 1.0) < 0.7
        elif signal == 'SELL':
            return analysis.get('trend') == 'BEARISH' and analysis.get('volatility', 1.0) < 0.7
        else:
            return True  # HOLD is always valid
            
    def format_currency(self, amount: float, decimals: int = 2) -> str:
        """Format currency amount for display"""
        return f"${amount:,.{decimals}f}"
        
    def calculate_profit_loss(self, entry_price: float, current_price: float, 
                            position_type: str, position_size: float) -> float:
        """Calculate profit/loss for a position"""
        if position_type.upper() == 'BUY':
            return (current_price - entry_price) * position_size
        elif position_type.upper() == 'SELL':
            return (entry_price - current_price) * position_size
        else:
            return 0.0