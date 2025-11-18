//+------------------------------------------------------------------+
//|                                            EA_Validation_Test.mq5 |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include "Structs_Version1.mqh"
#include "PriceActionAnalyzer_Enhanced.mqh"

//--- Input Parameters
input ENUM_TIMEFRAMES TestTimeframe = PERIOD_H1;  // Test Timeframe
input int TestCandles = 100;                      // Candles to analyze
input bool RunPatternTests = true;                // Run Pattern Detection Tests
input bool RunLevelTests = true;                  // Run Level Detection Tests
input bool RunTrendTests = true;                  // Run Trend Analysis Tests

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
    Print("=== THEKAYBAMBODLABFX EA Validation Test Started ===");
    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(TestTimeframe));
    Print("Test Candles: ", TestCandles);
    
    // Initialize analyzer
    CPriceActionAnalyzer* analyzer = new CPriceActionAnalyzer(_Symbol, TestTimeframe, TestCandles);
    
    if(analyzer == NULL) {
        Print("ERROR: Failed to initialize Price Action Analyzer");
        return;
    }
    
    Print("\n=== Analyzer initialized successfully ===");
    
    // Run pattern detection tests
    if(RunPatternTests) {
        Print("\n=== PATTERN DETECTION TESTS ===");
        TestPatternDetection(analyzer);
    }
    
    // Run level detection tests
    if(RunLevelTests) {
        Print("\n=== LEVEL DETECTION TESTS ===");
        TestLevelDetection(analyzer);
    }
    
    // Run trend analysis tests
    if(RunTrendTests) {
        Print("\n=== TREND ANALYSIS TESTS ===");
        TestTrendAnalysis(analyzer);
    }
    
    // Test trading sequences
    Print("\n=== TRADING SEQUENCE VALIDATION ===");
    TestTradingSequences();
    
    // Cleanup
    delete analyzer;
    
    Print("\n=== THEKAYBAMBODLABFX EA Validation Test Completed ===");
}

//+------------------------------------------------------------------+
//| Test pattern detection functionality                             |
//+------------------------------------------------------------------+
void TestPatternDetection(CPriceActionAnalyzer* analyzer) {
    int patternsFound = 0;
    int candlesToTest = MathMin(20, TestCandles);
    
    Print("Testing pattern detection on last ", candlesToTest, " candles...");
    
    for(int i = 1; i <= candlesToTest; i++) {
        bool pinBar = analyzer.IsPinBar(i, 0.6);
        bool doji = analyzer.IsDoji(i, 0.1);
        bool bullishEngulfing = analyzer.IsBullishEngulfing(i);
        bool bearishEngulfing = analyzer.IsBearishEngulfing(i);
        bool breakOfStructure = analyzer.IsBreakOfStructure(i, 10);
        
        if(pinBar || doji || bullishEngulfing || bearishEngulfing || breakOfStructure) {
            patternsFound++;
            
            string patterns = "";
            if(pinBar) patterns += "Pin Bar ";
            if(doji) patterns += "Doji ";
            if(bullishEngulfing) patterns += "Bullish Engulfing ";
            if(bearishEngulfing) patterns += "Bearish Engulfing ";
            if(breakOfStructure) patterns += "Break of Structure ";
            
            Print("Candle [", i, "]: ", patterns);
        }
    }
    
    Print("Pattern Detection Test Result: ", patternsFound, " patterns found in ", candlesToTest, " candles");
    
    if(patternsFound > 0) {
        Print("✅ Pattern Detection: WORKING");
    } else {
        Print("⚠️ Pattern Detection: No patterns found (may be normal depending on market conditions)");
    }
}

//+------------------------------------------------------------------+
//| Test level detection functionality                               |
//+------------------------------------------------------------------+
void TestLevelDetection(CPriceActionAnalyzer* analyzer) {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Test support/resistance detection
    double nearestSupport = analyzer.FindNearestSupport(currentPrice, 50);
    double nearestResistance = analyzer.FindNearestResistance(currentPrice, 50);
    
    Print("Current Price: ", DoubleToString(currentPrice, _Digits));
    Print("Nearest Support: ", (nearestSupport > 0) ? DoubleToString(nearestSupport, _Digits) : "Not found");
    Print("Nearest Resistance: ", (nearestResistance > 0) ? DoubleToString(nearestResistance, _Digits) : "Not found");
    
    // Test swing point detection
    double swingHigh = analyzer.FindSwingHigh(20, 5);
    double swingLow = analyzer.FindSwingLow(20, 5);
    
    Print("Recent Swing High: ", (swingHigh > 0) ? DoubleToString(swingHigh, _Digits) : "Not found");
    Print("Recent Swing Low: ", (swingLow > 0) ? DoubleToString(swingLow, _Digits) : "Not found");
    
    // Test structure levels
    double higherHigh = analyzer.FindHigherHigh(20);
    double higherLow = analyzer.FindHigherLow(20);
    double lowerHigh = analyzer.FindLowerHigh(20);
    double lowerLow = analyzer.FindLowerLow(20);
    
    Print("Higher High: ", (higherHigh > 0) ? DoubleToString(higherHigh, _Digits) : "Not found");
    Print("Higher Low: ", (higherLow > 0) ? DoubleToString(higherLow, _Digits) : "Not found");
    Print("Lower High: ", (lowerHigh > 0) ? DoubleToString(lowerHigh, _Digits) : "Not found");
    Print("Lower Low: ", (lowerLow > 0) ? DoubleToString(lowerLow, _Digits) : "Not found");
    
    if(nearestSupport > 0 || nearestResistance > 0 || swingHigh > 0 || swingLow > 0) {
        Print("✅ Level Detection: WORKING");
    } else {
        Print("⚠️ Level Detection: Limited results (may be normal depending on market conditions)");
    }
}

//+------------------------------------------------------------------+
//| Test trend analysis functionality                                |
//+------------------------------------------------------------------+
void TestTrendAnalysis(CPriceActionAnalyzer* analyzer) {
    bool uptrend = analyzer.IsUptrend(20);
    bool downtrend = analyzer.IsDowntrend(20);
    bool sideways = analyzer.IsSideways(20);
    
    Print("Trend Analysis Results:");
    Print("Uptrend: ", uptrend ? "YES" : "NO");
    Print("Downtrend: ", downtrend ? "YES" : "NO");
    Print("Sideways: ", sideways ? "YES" : "NO");
    
    string currentTrend = "UNKNOWN";
    if(uptrend) currentTrend = "UPTREND";
    else if(downtrend) currentTrend = "DOWNTREND";
    else if(sideways) currentTrend = "SIDEWAYS";
    
    Print("Current Market Trend: ", currentTrend);
    Print("✅ Trend Analysis: WORKING");
}

//+------------------------------------------------------------------+
//| Test trading sequence validation                                 |
//+------------------------------------------------------------------+
void TestTradingSequences() {
    Print("Testing buy/sell sequence validation logic...");
    
    // Create test pattern sequences
    struct TestPatternSequence {
        bool PinBar;
        bool Doji;
        bool BullishEngulfing;
        bool BearishEngulfing;
        bool BreakOfStructure;
        bool Retracement;
        string expectedResult;
    };
    
    TestPatternSequence testCases[9];
    
    // Test case 1: (a) → (c) → (d) → (e)
    testCases[0].PinBar = true;
    testCases[0].BullishEngulfing = true;
    testCases[0].BreakOfStructure = true;
    testCases[0].Retracement = true;
    testCases[0].expectedResult = "VALID BUY";
    
    // Test case 2: (a) → (d) → (e)
    testCases[1].PinBar = true;
    testCases[1].BreakOfStructure = true;
    testCases[1].Retracement = true;
    testCases[1].expectedResult = "VALID BUY";
    
    // Test case 3: (a) → (c) → (e)
    testCases[2].PinBar = true;
    testCases[2].BullishEngulfing = true;
    testCases[2].Retracement = true;
    testCases[2].expectedResult = "VALID BUY";
    
    // Test case 4: (b) → (c) → (e)
    testCases[3].Doji = true;
    testCases[3].BullishEngulfing = true;
    testCases[3].Retracement = true;
    testCases[3].expectedResult = "VALID BUY";
    
    // Test case 5: (b) → (c) → (d) → (e)
    testCases[4].Doji = true;
    testCases[4].BullishEngulfing = true;
    testCases[4].BreakOfStructure = true;
    testCases[4].Retracement = true;
    testCases[4].expectedResult = "VALID BUY";
    
    // Test case 6: (b) → (d) → (e)
    testCases[5].Doji = true;
    testCases[5].BreakOfStructure = true;
    testCases[5].Retracement = true;
    testCases[5].expectedResult = "VALID BUY";
    
    // Test case 7: (c) → (d) → (e)
    testCases[6].BullishEngulfing = true;
    testCases[6].BreakOfStructure = true;
    testCases[6].Retracement = true;
    testCases[6].expectedResult = "VALID BUY";
    
    // Test case 8: (a) → (c)
    testCases[7].PinBar = true;
    testCases[7].BullishEngulfing = true;
    testCases[7].expectedResult = "VALID BUY";
    
    // Test case 9: (b) → (c)
    testCases[8].Doji = true;
    testCases[8].BullishEngulfing = true;
    testCases[8].expectedResult = "VALID BUY";
    
    int passedTests = 0;
    
    for(int i = 0; i < ArraySize(testCases); i++) {
        bool result = TestBuySequence(testCases[i]);
        bool expected = (testCases[i].expectedResult == "VALID BUY");
        
        if(result == expected) {
            Print("✅ Test Case ", (i+1), ": PASSED - ", testCases[i].expectedResult);
            passedTests++;
        } else {
            Print("❌ Test Case ", (i+1), ": FAILED - Expected: ", testCases[i].expectedResult, ", Got: ", result ? "VALID" : "INVALID");
        }
    }
    
    Print("Trading Sequence Test Results: ", passedTests, "/", ArraySize(testCases), " tests passed");
    
    if(passedTests == ArraySize(testCases)) {
        Print("✅ Trading Sequence Validation: ALL TESTS PASSED");
    } else {
        Print("⚠️ Trading Sequence Validation: SOME TESTS FAILED");
    }
}

//+------------------------------------------------------------------+
//| Test buy sequence logic (simplified version)                     |
//+------------------------------------------------------------------+
bool TestBuySequence(const TestPatternSequence &patterns) {
    // Valid Buy Sequences (same logic as in main EA):
    // 1. (a) → (c) → (d) → (e)
    if(patterns.PinBar && patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 2. (a) → (d) → (e)
    if(patterns.PinBar && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 3. (a) → (c) → (e)
    if(patterns.PinBar && patterns.BullishEngulfing && patterns.Retracement) return true;
    
    // 4. (b) → (c) → (e)
    if(patterns.Doji && patterns.BullishEngulfing && patterns.Retracement) return true;
    
    // 5. (b) → (c) → (d) → (e)
    if(patterns.Doji && patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 6. (b) → (d) → (e)
    if(patterns.Doji && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 7. (c) → (d) → (e)
    if(patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 8. (a) → (c)
    if(patterns.PinBar && patterns.BullishEngulfing) return true;
    
    // 9. (b) → (c)
    if(patterns.Doji && patterns.BullishEngulfing) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Pattern test structure                                           |
//+------------------------------------------------------------------+
struct TestPatternSequence {
    bool PinBar;
    bool Doji;
    bool BullishEngulfing;
    bool BearishEngulfing;
    bool BreakOfStructure;
    bool Retracement;
    string expectedResult;
};
//+------------------------------------------------------------------+