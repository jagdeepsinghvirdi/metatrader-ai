import secrets
from metatrader_ai.agent import run


def main():
    """Run the program with local secrets.py credentials."""
    run(
        api_key=secrets.OPENAI_API_KEY,
        account_login=secrets.ACCOUNT_NUMBER,
        account_password=secrets.ACCOUNT_PASSWORD,
        broker_server_name=secrets.BROKER_SERVER_NAME,
    )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\033[90mOperation cancelled by user.\033[0m")
