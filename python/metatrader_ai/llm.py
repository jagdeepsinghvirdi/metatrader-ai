OPENAI = 0
DEEPSEEK = 1

class LLM:
    """LLM provider config with endpoint URL, model name, and API key."""
    __slots__ = ["provider_id", "id", "label", "model", "url"]

    def __init__(self, provider_id: int = DEEPSEEK):
        self.id = ""
        self.label = ""
        self.model = ""
        self.url = ""

        if provider_id == OPENAI:
            self.id = "openai"
            self.label = "OpenAI"
            self.model = "gpt-5.4-mini"
            self.url = "https://api.openai.com/v1/chat/completions"
        elif provider_id == DEEPSEEK:
            self.id = "deepseek"
            self.label = "DeepSeek"
            self.model = "deepseek-v4-flash"
            self.url = "https://api.deepseek.com/chat/completions"
        else:
            raise ValueError("Invalid provider_id. Must be 0 (OpenAI) or 1 (DeepSeek).")
    