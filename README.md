# KAYBAMBODLABFX
BOT_STRATEGY

## Overview
KAYBAMBODLABFX is a FOREX trading bot with configurable strategies for automated currency trading. The bot includes market analysis, risk management, and backtesting capabilities.

## Programs Included

### 1. bot_strategy.py
Main trading bot program that:
- Analyzes market conditions for currency pairs
- Executes trades based on configurable strategies
- Manages portfolio and positions
- Logs all trading activities

### 2. config.py
Configuration management module that:
- Loads and validates bot settings
- Manages trading parameters
- Handles default configurations
- Provides configuration updates

### 3. utils.py
Trading utility functions including:
- Technical indicators (SMA, EMA, RSI)
- Risk management calculations
- Price data generation
- Market analysis tools

### 4. backtest.py
Backtesting engine that:
- Simulates trading strategies
- Tests performance over historical periods
- Generates performance reports
- Saves results for analysis

### 5. config.json
Configuration file containing:
- Trading pairs and parameters
- Risk management settings
- Strategy configurations
- Technical indicator settings

## Usage

### Running the Bot Strategy
```bash
python3 bot_strategy.py
```

### Running Backtests
```bash
python3 backtest.py
```

### Configuration
Edit `config.json` to customize:
- Initial balance and trade amounts
- Trading pairs to monitor
- Risk levels and stop-loss settings
- Technical indicator parameters

## Features
- **Multi-pair Trading**: Support for major FOREX pairs
- **Risk Management**: Configurable stop-loss and take-profit levels
- **Technical Analysis**: Built-in indicators and trend analysis
- **Backtesting**: Historical performance testing
- **Logging**: Comprehensive trade and activity logging
- **Configurable**: Easy-to-modify settings via JSON configuration

## Requirements
- Python 3.6 or higher
- See `requirements.txt` for dependencies

## Getting Started
1. Clone the repository
2. Configure settings in `config.json`
3. Run backtests to validate strategy: `python3 backtest.py`
4. Start the bot: `python3 bot_strategy.py`

## Risk Warning
This software is for educational and testing purposes. Trading FOREX involves substantial risk and may not be suitable for all investors. Always test strategies thoroughly before using real money.
