from metatrader_ai.app import launch
from metatrader_ai.agent import Agent
from metatrader_ai.llm import DEEPSEEK
from secrets import DEEPSEEK_API_KEY, ACCOUNT_NUMBER, ACCOUNT_PASSWORD, BROKER_SERVER_NAME

agent = Agent(
    account_login=ACCOUNT_NUMBER,
    account_password=ACCOUNT_PASSWORD,
    broker_server_name=BROKER_SERVER_NAME,
    api_key=DEEPSEEK_API_KEY,
    model=DEEPSEEK
)

launch(agent=agent)