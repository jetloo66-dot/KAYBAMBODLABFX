#!/usr/bin/env python3
"""
Backtesting program for KAYBAMBODLABFX bot strategy
"""

import json
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
from config import BotConfig
from utils import TradingUtils

class BacktestEngine:
    """Backtesting engine for trading strategies"""
    
    def __init__(self, config_file: str = "config.json"):
        self.config = BotConfig(config_file)
        self.utils = TradingUtils()
        self.trades = []
        self.balance_history = []
        self.initial_balance = self.config.initial_balance
        self.current_balance = self.initial_balance
        
    def simulate_market_analysis(self, price_data: Dict) -> Dict:
        """Simulate market analysis for backtesting"""
        # Generate random but consistent analysis based on price movement
        price_change = (price_data['close'] - price_data['open']) / price_data['open']
        
        if price_change > 0.005:  # 0.5% increase
            trend = 'BULLISH'
            signal = 'BUY'
        elif price_change < -0.005:  # 0.5% decrease
            trend = 'BEARISH'
            signal = 'SELL'
        else:
            trend = 'SIDEWAYS'
            signal = 'HOLD'
            
        return {
            'pair': price_data['pair'],
            'trend': trend,
            'volatility': abs(price_change) * 10,  # Scale volatility
            'signal': signal,
            'price': price_data['close']
        }
        
    def execute_backtest_trade(self, analysis: Dict, timestamp: str) -> bool:
        """Execute a trade during backtesting"""
        if analysis['signal'] == 'HOLD':
            return False
            
        if self.current_balance < self.config.trade_amount:
            return False
            
        trade = {
            'timestamp': timestamp,
            'pair': analysis['pair'],
            'signal': analysis['signal'],
            'entry_price': analysis['price'],
            'amount': self.config.trade_amount,
            'status': 'OPEN'
        }
        
        self.trades.append(trade)
        self.current_balance -= self.config.trade_amount
        return True
        
    def close_positions(self, current_data: Dict):
        """Close open positions based on current market data"""
        for trade in self.trades:
            if trade['status'] == 'OPEN' and trade['pair'] == current_data['pair']:
                # Simple exit strategy: close after price moves 2% in favor or 1% against
                entry_price = trade['entry_price']
                current_price = current_data['close']
                
                if trade['signal'] == 'BUY':
                    price_change = (current_price - entry_price) / entry_price
                    if price_change >= 0.02 or price_change <= -0.01:  # 2% profit or 1% loss
                        self.close_position(trade, current_price)
                        
                elif trade['signal'] == 'SELL':
                    price_change = (entry_price - current_price) / entry_price
                    if price_change >= 0.02 or price_change <= -0.01:  # 2% profit or 1% loss
                        self.close_position(trade, current_price)
                        
    def close_position(self, trade: Dict, exit_price: float):
        """Close a specific position"""
        trade['exit_price'] = exit_price
        trade['status'] = 'CLOSED'
        
        # Calculate profit/loss
        profit_loss = self.utils.calculate_profit_loss(
            trade['entry_price'], 
            exit_price, 
            trade['signal'], 
            trade['amount']
        )
        
        trade['profit_loss'] = profit_loss
        self.current_balance += trade['amount'] + profit_loss
        
    def run_backtest(self, days: int = 30) -> Dict:
        """Run backtest simulation"""
        print(f"Running backtest for {days} days...")
        
        results = {
            'start_date': (datetime.now() - timedelta(days=days)).isoformat(),
            'end_date': datetime.now().isoformat(),
            'initial_balance': self.initial_balance,
            'final_balance': self.current_balance,
            'total_trades': 0,
            'winning_trades': 0,
            'losing_trades': 0,
            'total_profit': 0.0,
            'total_loss': 0.0,
            'win_rate': 0.0,
            'roi': 0.0,
            'pairs_tested': []
        }
        
        # Test each trading pair
        for pair in self.config.trading_pairs:
            print(f"Testing pair: {pair}")
            price_data = self.utils.generate_price_data(pair, days)
            
            for data_point in price_data:
                # Analyze market
                analysis = self.simulate_market_analysis(data_point)
                
                # Close existing positions first
                self.close_positions(data_point)
                
                # Execute new trades
                if self.execute_backtest_trade(analysis, data_point['timestamp']):
                    results['total_trades'] += 1
                    
                # Record balance
                self.balance_history.append({
                    'timestamp': data_point['timestamp'],
                    'balance': self.current_balance
                })
                
            results['pairs_tested'].append(pair)
            
        # Close any remaining open positions at final prices
        for trade in self.trades:
            if trade['status'] == 'OPEN':
                final_price = self.utils.get_current_price(trade['pair'])
                self.close_position(trade, final_price)
                
        # Calculate final statistics
        results['final_balance'] = self.current_balance
        
        closed_trades = [t for t in self.trades if t['status'] == 'CLOSED']
        winning_trades = [t for t in closed_trades if t.get('profit_loss', 0) > 0]
        losing_trades = [t for t in closed_trades if t.get('profit_loss', 0) < 0]
        
        results['total_trades'] = len(closed_trades)
        results['winning_trades'] = len(winning_trades)
        results['losing_trades'] = len(losing_trades)
        results['total_profit'] = sum(t.get('profit_loss', 0) for t in winning_trades)
        results['total_loss'] = sum(abs(t.get('profit_loss', 0)) for t in losing_trades)
        
        if results['total_trades'] > 0:
            results['win_rate'] = (results['winning_trades'] / results['total_trades']) * 100
            
        results['roi'] = ((results['final_balance'] - results['initial_balance']) / results['initial_balance']) * 100
        
        return results
        
    def save_backtest_results(self, results: Dict, filename: str = "backtest_results.json"):
        """Save backtest results to file"""
        with open(filename, 'w') as f:
            json.dump(results, f, indent=4)
        print(f"Backtest results saved to {filename}")
        
    def print_backtest_summary(self, results: Dict):
        """Print backtest summary"""
        print("\n" + "="*50)
        print("BACKTEST RESULTS SUMMARY")
        print("="*50)
        print(f"Test Period: {results['start_date'][:10]} to {results['end_date'][:10]}")
        print(f"Initial Balance: ${results['initial_balance']:,.2f}")
        print(f"Final Balance: ${results['final_balance']:,.2f}")
        print(f"Total Return: ${results['final_balance'] - results['initial_balance']:,.2f}")
        print(f"ROI: {results['roi']:.2f}%")
        print(f"Total Trades: {results['total_trades']}")
        print(f"Winning Trades: {results['winning_trades']}")
        print(f"Losing Trades: {results['losing_trades']}")
        print(f"Win Rate: {results['win_rate']:.1f}%")
        print(f"Total Profit: ${results['total_profit']:,.2f}")
        print(f"Total Loss: ${results['total_loss']:,.2f}")
        print(f"Pairs Tested: {', '.join(results['pairs_tested'])}")
        print("="*50)

def main():
    """Main backtesting entry point"""
    print("KAYBAMBODLABFX - Backtesting Engine")
    print("="*40)
    
    try:
        # Create backtest engine
        backtest = BacktestEngine()
        
        # Run backtest
        results = backtest.run_backtest(days=30)
        
        # Display results
        backtest.print_backtest_summary(results)
        
        # Save results
        backtest.save_backtest_results(results)
        
        return 0
        
    except Exception as e:
        print(f"Error during backtesting: {e}")
        return 1

if __name__ == "__main__":
    exit(main())