from metatrader_ai.app import launch
from metatrader_ai.agent import Agent
from secrets import OPENAI_API_KEY, ACCOUNT_NUMBER, ACCOUNT_PASSWORD, BROKER_SERVER_NAME

agent = Agent(
    api_key=OPENAI_API_KEY,
    account_login=ACCOUNT_NUMBER,
    account_password=ACCOUNT_PASSWORD,
    broker_server_name=BROKER_SERVER_NAME,
)

launch(agent=agent)