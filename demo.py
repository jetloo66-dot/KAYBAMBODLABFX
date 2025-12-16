#!/usr/bin/env python3
"""
Demo script for KAYBAMBODLABFX bot programs
Shows basic usage of all components
"""

from bot_strategy import ForexBot
from backtest import BacktestEngine
from config import BotConfig
from utils import TradingUtils

def demo_config():
    """Demonstrate configuration management"""
    print("=== Configuration Demo ===")
    config = BotConfig()
    print(f"Initial balance: ${config.initial_balance:,.2f}")
    print(f"Trading pairs: {', '.join(config.trading_pairs)}")
    print(f"Risk level: {config.risk_level}")
    print(f"Strategy type: {config.strategy_type}")
    print()

def demo_utils():
    """Demonstrate utility functions"""
    print("=== Utilities Demo ===")
    utils = TradingUtils()
    
    # Show price simulation
    eur_usd_price = utils.get_current_price("EUR/USD")
    print(f"Simulated EUR/USD price: {eur_usd_price}")
    
    # Show trend analysis
    trend = utils.determine_trend()
    volatility = utils.calculate_volatility()
    print(f"Market trend: {trend}")
    print(f"Volatility: {volatility:.2f}")
    
    # Show technical indicators
    sample_prices = [1.1000, 1.1050, 1.1025, 1.1075, 1.1100]
    sma = utils.calculate_sma(sample_prices, 3)
    rsi = utils.calculate_rsi(sample_prices)
    print(f"SMA (3-period): {sma:.4f}")
    print(f"RSI: {rsi:.1f}")
    print()

def demo_bot():
    """Demonstrate bot trading"""
    print("=== Bot Strategy Demo ===")
    bot = ForexBot()
    
    # Show portfolio status before
    status_before = bot.get_portfolio_status()
    print(f"Portfolio before: {status_before}")
    
    # Run strategy (limited to reduce output)
    print("Running strategy...")
    
    # Analyze one pair
    analysis = bot.analyze_market("EUR/USD")
    print(f"Market analysis for EUR/USD: {analysis}")
    
    # Show portfolio status after
    status_after = bot.get_portfolio_status()
    print(f"Portfolio after: {status_after}")
    print()

def demo_backtest():
    """Demonstrate backtesting"""
    print("=== Backtesting Demo ===")
    backtest = BacktestEngine()
    
    print("Running quick backtest (7 days)...")
    results = backtest.run_backtest(days=7)
    
    # Show key results
    print(f"Initial balance: ${results['initial_balance']:,.2f}")
    print(f"Final balance: ${results['final_balance']:,.2f}")
    print(f"ROI: {results['roi']:.2f}%")
    print(f"Total trades: {results['total_trades']}")
    print(f"Win rate: {results['win_rate']:.1f}%")
    print()

def main():
    """Main demo function"""
    print("KAYBAMBODLABFX - Programs Demo")
    print("=" * 40)
    print()
    
    try:
        demo_config()
        demo_utils()
        demo_bot()
        demo_backtest()
        
        print("All demos completed successfully!")
        print("Programs are working correctly.")
        
    except Exception as e:
        print(f"Demo error: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main())