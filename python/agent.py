import json
import os
import requests
import secrets
from tools import dispatch, mt5

BASE_DIR = os.path.dirname(__file__)
PROJECT_DIR = os.path.dirname(BASE_DIR)

MODEL = "gpt-5-nano"
URL = "https://api.openai.com/v1/chat/completions"
HEADERS = {
    "Authorization": f"Bearer {secrets.OPENAI_API_KEY}",
    "Content-Type": "application/json",
}

CONTEXT_FILES = [
    "context/python.md",
    "context/trade.md",
    "workflows/response.md",
]


def initialize_messages() -> list[dict]:
    """Build initial system context for a multi-turn conversation."""
    system_content = get_prompt() + load_markdown_files(CONTEXT_FILES)
    return [{"role": "system", "content": system_content}]


def get_prompt() -> str:
    """Returns the system prompt from context/prompt.md."""
    prompt_path = os.path.join(PROJECT_DIR, "context", "prompt.md")
    with open(prompt_path, "r", encoding="utf-8") as f:
        return f.read()


def load_markdown_files(file_paths: list[str]) -> str:
    """Read markdown files relative to the project root and return their combined content."""
    combined = ""
    for rel_path in file_paths:
        full_path = os.path.join(PROJECT_DIR, rel_path)
        with open(full_path, "r", encoding="utf-8") as f:
            combined += f"\n\n--- {rel_path} ---\n{f.read()}"
    return combined


def run_agent(messages: list[dict], prompt: str):
    """Process one user turn and return the assistant response."""
    messages.append({"role": "user", "content": prompt})
    tools = dispatch.get_tool_list()

    try:
        while True:
            payload: dict = {
                "model": MODEL,
                "messages": messages,
                "tools": tools,
                "tool_choice": "auto",
            }

            response = requests.post(URL, headers=HEADERS, json=payload, timeout=60)

            if not response.ok:
                try:
                    detail = response.json()
                except ValueError:
                    detail = response.text
                return f"API error {response.status_code}: {detail}"

            data = response.json()
            message = data["choices"][0]["message"]

            if not message.get("tool_calls"):
                assistant_content = message.get("content") or ""
                messages.append({"role": "assistant", "content": assistant_content})
                return assistant_content

            assistant_msg: dict = {
                "role": "assistant",
                "tool_calls": message["tool_calls"],
            }
            if message.get("content") is not None:
                assistant_msg["content"] = message["content"]
            messages.append(assistant_msg)

            for tool_call in message["tool_calls"]:
                name = tool_call["function"]["name"]
                raw_args = tool_call["function"].get("arguments") or "{}"
                args = json.loads(raw_args)
                result = dispatch.execute_tool(name, args)

                messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": tool_call["id"],
                        "content": str(result),
                    }
                )
    except (
        requests.RequestException,
        RuntimeError,
        ValueError,
        TypeError,
        KeyError,
    ) as e:
        return f"An error occurred during processing: {e}"


def main():
    """Run the program"""
    metatrader_client = mt5.MT5(
        secrets.ACCOUNT_NUMBER,
        secrets.ACCOUNT_PASSWORD,
        secrets.BROKER_SERVER_NAME,
    )
    dispatch.set_metatrader(metatrader_client)

    if not metatrader_client.login():
        print(
            "\033[91mFailed to connect to MetaTrader. Please check your credentials and connection.\033[0m"
        )
        return

    messages = initialize_messages()

    while True:
        prompt = input("\033[93m>>> \033[0m").strip()

        if not prompt:
            continue

        if prompt.lower() in {"exit", "quit", "q"}:
            print("\033[90mGoodbye.\033[0m")
            break

        print(run_agent(messages, prompt))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\033[90mOperation cancelled by user.\033[0m")
