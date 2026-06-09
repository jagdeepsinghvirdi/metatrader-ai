# MetaTrader AI
An AI-powered trading assistant for MetaTrader 4 and MetaTrader 5! Now you can use AI in your trading strategies.

## Features

| Feature | Python | MQL |
|---------|--------|-----|
| Open, close, modify positions & orders | ✅ | ✅ |
| Modify SL, TP, and entry prices | ✅ | ✅ |
| Fetch positions, orders, and deal history | ✅ | ✅ |
| Account info (balance, equity, margin, etc.) | ✅ | ✅ |
| Symbol info (bid, ask, spread, digits, lots) | ✅ | ✅ |
| OHLCV bars and individual bar prices | ✅ | ✅ |
| Pip value and risk-based lot sizing | ✅ | ✅ |
| MQL5 file compilation | ✅ | ✅ |
| 20+ technical indicators (MA, RSI, ATR, ADX, MACD, Stochastic, CCI, WPR, Momentum, Envelopes, Fractals, Bulls/Bears Power, VWAP, PVI, AO, ADR, ATHR, custom) | — | ✅ |
| Chart screenshots and analysis | — | ✅ |
| Open, close, and inspect charts | — | ✅ |
| Enable/disable symbols in Market Watch | — | ✅ |
| Terminal info (OS, CPU, memory, build, connection) | — | ✅ |
| File operations (read, write, copy, move, delete) | — | ✅ |
| Chat GUI (desktop or on-chart panel) | ✅ Desktop | ✅ On-chart |

## Requirements
- Windows operating system (for Python integration, MQL works on all platforms that MetaTrader supports)
- MetaTrader 5 and Python 3.9.7 or higher for Python integration
- MetaTrader 4 or MetaTrader 5 for MQL integration
- OpenAI API key

## Installation

### Python Package Usage (pip)

Install from PyPI:

```bash
pip install metatrader-ai
```

Use the convenience function (one-shot if prompt is provided, interactive mode if omitted):

```python
from metatrader_ai.agent import run

result = run(
      api_key=API_KEY,
      account_login=ACCOUNT_LOGIN,
      account_password=ACCOUNT_PASS,
      broker_server_name=BROKER_NAME,
      prompt="What is the daily high of ETHUSD?",
)
```

Use the class API for multi-turn conversations:

```python
from metatrader_ai.agent import Agent

agent = Agent(API_KEY, ACCOUNT_LOGIN, ACCOUNT_PASS, BROKER_NAME)
response = agent.run("What is the daily high of ETHUSD?")
print(response)
```

Use the command line entrypoint:

```bash
metatrader-ai \
   --api-key "$OPENAI_API_KEY" \
   --account-login "$ACCOUNT_LOGIN" \
   --account-pass "$ACCOUNT_PASS" \
   --broker-name "$BROKER_NAME"
```

Optional single prompt mode:

```bash
metatrader-ai --prompt "Show account info" ...
```

### MQL
1. Open up Terminal and navigate to where MetaTrader's data folder is located. You can find this by going to MetaTrader, clicking on File > Open Data Folder. Then copy and paste that path into your terminal:
```bash
cd "C:\Users\YourUsername\AppData\Roaming\MetaQuotes\Terminal\YourTerminalID"
```
2. Navigate to the MQL4 or MQL5 folder, depending on which version of MetaTrader you are using:
```bash
cd MQL4
```
3. Navigate into the Includes folder:
```bash
cd Include
```
4. Clone (or download) this repository into the Includes folder:
```bash
git clone https://github.com/jblanked/metatrader-ai.git
```
5. Create a file called `secrets.mqh`

**Windows:**
```
ni secrets.mqh 
```
**Mac/Linux:**
```bash
touch secrets.mqh
```
6. Add your OpenAI API key to the `secrets.mqh` file:
```c++
#define OPENAI_API_KEY "your_openai_api_key"
```
Or define `OPENAI_API_KEY` in your own code before including the `agent.mqh` file.

7. Open up MetaTrader and you should see the `metatrader-ai` folder in the Navigator under Include. You can now include the `agent.mqh` file in your MQL scripts to use the AI functions:
```c++
#include <metatrader-ai/mql/agent.mqh>

void OnStart()
{
   Agent *agent = new Agent();

    // get a response
   string response = agent.run("What is the daily high of ETHUSD?");
   Print("[Agent] ", response);

   delete agent; // clean up the agent
}
```

Or you can compile and run the `app.mq5` file (within the `metatrader-ai/mql` folder) to see a demo of the AI assistant in action. It will create a panel on your chart where you can type in prompts and see the AI's responses.


## Notes
-  I am available for hire to integrate your strategy into the system, with advanced prompts and multi layer thinking: https://www.jblanked.com/coding-request/
- I configured this with one of the cheapest models, gpt-5-nano, which is $0.05 for 1 million tokens. You can use a smarter model, and optionally switch to claude, but for basic trading logic, the nano is sufficient and very cost effective (roughly $0.05 per 50 requests)
- The python environment works best directly inside of MetaTrader5, but if you run it from a Windows/Linux Terminal, you should open up MetaTrader5 and log in to your account first, then run the python script for the best experience. The script attempts to open and login to MetaTrader5 if it is not already open.

## Disclaimer
Trading and investing involve substantial risk. Past performance is not indicative of future results. This software is provided for educational and informational purposes only and should not be considered as financial advice. Always do your own research and consult with a qualified financial advisor before making any trading decisions. JBlanked and the developers of this software are not responsible for any losses or damages that may occur from using this software.