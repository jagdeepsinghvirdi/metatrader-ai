# MetaTrader AI
An AI-powered trading assistant for MetaTrader 4 and MetaTrader 5! Now you can use AI in your trading strategies.

The Assistant can:
- Open positions and pending orders
- Close positions
- Delete pending orders
- Modify stop loss and take profit levels
- Get current and historical price data
- Get account information and trading history

## Requirements
- Windows or Linux operating system
- MetaTrader 4 or MetaTrader 5
- Python 3.9.7 or higher
- OpenAI API key

## Installation

### Python
1. Clone (or download) this repository: `git clone https://github.com/jblanked/metatrader-ai.git`
2. Create a virtual environment and install the required dependencies:

**Windows:**
```py
cd metatrader-ai/python
python -m venv venv
./venv/Scripts/activate
pip install -r requirements.txt
ni secrets.py 
```
**Linux:**
```py
cd metatrader-ai/python
python3 -m venv venv
source venv/bin/activate 
pip install -r requirements.txt
touch secrets.py 
```
3. Open `secrets.py` and add your OpenAI API key, Account Number, Account Password, and Broker Server Name:
```py
OPENAI_API_KEY = "your_openai_api_key"
ACCOUNT_NUMBER = 123456
ACCOUNT_PASSWORD = "your_account_password"
BROKER_SERVER_NAME = "your_broker_server"
```
4. Run the Python script to start the AI assistant:
```py
python agent.py
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
**Linux:**
```bash
touch secrets.mqh
```
6. Add your OpenAI API key to the `secrets.mqh` file:
```c++
#define OPENAI_API_KEY "your_openai_api_key"
```
7. Open up MetaTrader and you should see the `metatrader-ai` folder in the Navigator under Include. You can now include the `agent.mqh` file in your MQL scripts to use the AI functions:
```c++
#include <metatrader-ai/mql/agent.mqh>

void OnStart()
{
   agentInit(); // initialize the agent

    // get a response
   string response = agentRun("What is the daily high of ETHUSD?");
   Print("[Agent] ", response);

   agentDeinit(); // clean up the agent
}
```


## Notes
-  I am available for hire to integrate your strategy into the system, with advanced prompts and multi layer thinking: https://www.jblanked.com/coding-request/
- I configured this with one of the cheapest models, gpt-5-nano, which is $0.05 for 1 million tokens. You can use a smarter model, and optionally switch to claude, but for basic trading logic, the nano is sufficient and very cost effective (roughly $0.05 per 50 requests)
- The python environment works best directly inside of MetaTrader5, but if you run it from a Windows/Linux Terminal, you should open up MetaTrader5 and log in to your account first, then run the python script for the best experience. The script attempts to open and login to MetaTrader5 if it is not already open.

## Disclaimer
Trading and investing involve substantial risk. Past performance is not indicative of future results. This software is provided for educational and informational purposes only and should not be considered as financial advice. Always do your own research and consult with a qualified financial advisor before making any trading decisions. JBlanked and the developers of this software are not responsible for any losses or damages that may occur from using this software.