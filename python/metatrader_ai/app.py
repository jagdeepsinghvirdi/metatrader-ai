"""MetaTrader-AI desktop GUI (customtkinter)."""

from __future__ import annotations

import threading
from datetime import datetime
from typing import Optional

import customtkinter as ctk

from .agent import Agent

# Color palette
COLOR_BG = "#1E1E1E"
COLOR_USER_BUBBLE = "#0A84FF"
COLOR_AI_BUBBLE = "#37373C"
COLOR_USER_TEXT = "#FFFFFF"
COLOR_AI_TEXT = "#DCDCDC"
COLOR_TAB_ACTIVE = "#323237"
COLOR_TAB_INACTIVE = "#232328"
COLOR_TAB_TEXT = "#C8C8C8"
COLOR_INPUT_BG = "#2D2D32"
COLOR_SEND_BTN = "#0A84FF"
COLOR_SEND_TEXT = "#FFFFFF"
COLOR_ACCENT = "#0A84FF"
COLOR_BORDER = "#3C3C41"
COLOR_INFO_KEY = "#A0A0A0"
COLOR_INFO_VAL = "#DCDCDC"
COLOR_HEADER_BG = "#28282D"

FONT_FAMILY = "Consolas"
FONT_SIZES = {
    "tab": 12, "msg": 11, "input": 11, "send": 11,
    "info_key": 10, "info_val": 10, "header": 12, "scroll": 9,
}


class ScrollableChatFrame(ctk.CTkFrame):
    """Single textbox chat view — wrapping and scrolling handled natively."""

    def __init__(self, master, **kwargs):
        super().__init__(master, **kwargs)
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self._txt = ctk.CTkTextbox(
            self, wrap="word",
            fg_color="transparent", text_color=COLOR_AI_TEXT,
            font=(FONT_FAMILY, FONT_SIZES["msg"]),
            border_width=0,
            activate_scrollbars=True,
        )
        self._txt.grid(row=0, column=0, sticky="nsew", padx=4, pady=4)
        self._txt.insert("0.0", "")
        self._txt.configure(state="disabled")

        # User prefix tag
        self._txt._textbox.tag_config("user_prefix",
                                      foreground=COLOR_ACCENT,
                                      font=(FONT_FAMILY, FONT_SIZES["msg"], "bold"))

    def add_message(self, role: str, text: str, timestamp: str = "") -> None:
        self._txt.configure(state="normal")

        prefix = f"[{timestamp}] " if timestamp else ""
        if role == "user":
            prefix += "You: "
            tag = "user_prefix"
        else:
            prefix += "AI: "
            tag = ""

        self._txt.insert("end", prefix, tag)
        self._txt.insert("end", text + "\n\n")
        self._txt.configure(state="disabled")
        self._txt.yview_moveto(1.0)

    def clear(self) -> None:
        self._txt.configure(state="normal")
        self._txt.delete("0.0", "end")
        self._txt.configure(state="disabled")


class ScrollableInfoFrame(ctk.CTkScrollableFrame):
    """Scrollable terminal/symbol/account info."""

    def __init__(self, master, mt5_client=None, **kwargs):
        super().__init__(master, **kwargs)
        self.grid_columnconfigure(0, weight=1)
        self._mt5 = mt5_client
        self._info_rows: list[ctk.CTkFrame] = []

    def clear(self) -> None:
        for w in self._info_rows:
            w.destroy()
        self._info_rows.clear()

    def refresh(self) -> None:
        """Rebuild info rows from MetaTrader state."""
        self.clear()

        if self._mt5 is None:
            self._show_error("No MetaTrader client available.")
            return

        if not self._mt5.is_connected:
            self._show_error("MetaTrader not connected.\nStart MetaTrader 5 and try again.")
            return

        rows: list[tuple[str, str, bool]] = []

        # Terminal Info
        ti = self._mt5.terminal_info
        rows.append(("── Terminal Info ──", "", True))
        if ti:
            rows.append(("Name", str(getattr(ti, "name", "")), False))
            rows.append(("Data Path", str(getattr(ti, "data_path", "")), False))
            rows.append(("Build", str(getattr(ti, "build", "")), False))
            rows.append(("Max Bars", str(getattr(ti, "maxbars", "")), False))
            rows.append(("Connected", "Yes" if getattr(ti, "connected", False) else "No", False))
            rows.append(("Trade Allowed", "Yes" if getattr(ti, "trade_allowed", False) else "No", False))
            rows.append(("DLLs Allowed", "Yes" if getattr(ti, "dlls_allowed", False) else "No", False))

        # Symbol Info
        symbol_name = self._pick_symbol()
        si = self._mt5.get_symbol_info(symbol_name) if symbol_name else {}
        rows.append(("", "", False))
        rows.append(("── Symbol Info ──", "", True))
        if si:
            rows.append(("Symbol", symbol_name, False))
            rows.append(("Bid", str(si.get("bid", "")), False))
            rows.append(("Ask", str(si.get("ask", "")), False))
            rows.append(("Spread", str(si.get("spread", "")), False))
            rows.append(("Digits", str(si.get("digits", "")), False))
            rows.append(("Point", str(si.get("point", "")), False))
            rows.append(("Tick Value", str(si.get("tick_value", "")), False))
            rows.append(("Volume Max", str(si.get("max_lot_size", "")), False))

        # Account Info
        ai = self._mt5.account_info
        rows.append(("", "", False))
        rows.append(("── Account Info ──", "", True))
        if ai:
            rows.append(("Login", str(getattr(ai, "login", "")), False))
            rows.append(("Name", str(getattr(ai, "name", "")), False))
            rows.append(("Company", str(getattr(ai, "company", "")), False))
            rows.append(("Currency", str(getattr(ai, "currency", "")), False))
            rows.append(("Balance", f"{getattr(ai, 'balance', 0):.2f}", False))
            rows.append(("Equity", f"{getattr(ai, 'equity', 0):.2f}", False))
            rows.append(("Margin", f"{getattr(ai, 'margin', 0):.2f}", False))
            rows.append(("Free Margin", f"{getattr(ai, 'margin_free', 0):.2f}", False))
            rows.append(("Margin Level", f"{getattr(ai, 'margin_level', 0):.2f}", False))
            rows.append(("Profit", f"{getattr(ai, 'profit', 0):.2f}", False))
            rows.append(("Leverage", str(getattr(ai, "leverage", "")), False))

        self._build_rows(rows)

    def _pick_symbol(self) -> str:
        """Return a symbol from open positions, or a safe default."""
        try:
            positions = self._mt5.get_positions()
            if positions:
                return positions[0].get("symbol", "EURUSD")
        except Exception:
            pass
        return "EURUSD"

    def _show_error(self, msg: str) -> None:
        lbl = ctk.CTkLabel(
            self, text=msg, text_color="#FF6B6B",
            font=(FONT_FAMILY, FONT_SIZES["info_val"]),
        )
        lbl.pack(pady=40)
        self._info_rows.append(lbl)

    def _build_rows(self, rows: list[tuple[str, str, bool]]) -> None:
        for key, val, is_header in rows:
            row_frame = ctk.CTkFrame(self, fg_color="transparent")
            row_frame.pack(fill="x", padx=8, pady=(0, 1))
            row_frame.grid_columnconfigure(1, weight=1)

            if is_header:
                lbl = ctk.CTkLabel(
                    row_frame, text=key, text_color=COLOR_ACCENT,
                    font=(FONT_FAMILY, FONT_SIZES["header"], "bold"),
                    anchor="w", fg_color=COLOR_HEADER_BG,
                    corner_radius=4, padx=8, pady=4,
                )
                lbl.pack(fill="x")
            elif key == "" and val == "":
                lbl = ctk.CTkLabel(row_frame, text="", height=4)
                lbl.pack(fill="x")
            else:
                key_lbl = ctk.CTkLabel(
                    row_frame, text=key, text_color=COLOR_INFO_KEY,
                    font=(FONT_FAMILY, FONT_SIZES["info_key"]), anchor="w",
                )
                key_lbl.grid(row=0, column=0, sticky="w", padx=(8, 4))

                val_lbl = ctk.CTkLabel(
                    row_frame, text=val, text_color=COLOR_INFO_VAL,
                    font=(FONT_FAMILY, FONT_SIZES["info_val"]), anchor="e",
                )
                val_lbl.grid(row=0, column=1, sticky="e", padx=(4, 8))

            self._info_rows.append(row_frame)


class App(ctk.CTk):
    """Main window — Chat and Info tabs."""

    def __init__(
        self,
        agent: Optional[Agent] = None,
        title: str = "MetaTrader-AI",
        width: int = 520,
        height: int = 700,
    ):
        super().__init__()
        self.title(title)
        self.geometry(f"{width}x{height}")
        self.minsize(400, 500)

        ctk.set_appearance_mode("Dark")
        ctk.set_default_color_theme("dark-blue")
        self.configure(fg_color=COLOR_BG)

        self._agent = agent
        self._message_history: list[dict[str, str]] = []
        self._request_pending = False
        self._pending_msg: str = ""

        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(1, weight=1)

        self._tab_frame = ctk.CTkFrame(self, fg_color="transparent", height=32)
        self._tab_frame.grid(row=0, column=0, sticky="ew", padx=0, pady=0)
        self._tab_frame.grid_columnconfigure((0, 1), weight=0)
        self._tab_frame.grid_columnconfigure(2, weight=1)

        tab_w, tab_h = 100, 30

        self._btn_chat = ctk.CTkButton(
            self._tab_frame, text="Chat", width=tab_w, height=tab_h,
            font=(FONT_FAMILY, FONT_SIZES["tab"]),
            fg_color=COLOR_TAB_ACTIVE, hover_color=COLOR_TAB_ACTIVE,
            text_color=COLOR_TAB_TEXT, corner_radius=0,
            command=self._switch_to_chat,
        )
        self._btn_chat.grid(row=0, column=0, padx=(0, 1))

        self._btn_info = ctk.CTkButton(
            self._tab_frame, text="Info", width=tab_w, height=tab_h,
            font=(FONT_FAMILY, FONT_SIZES["tab"]),
            fg_color=COLOR_TAB_INACTIVE, hover_color=COLOR_TAB_INACTIVE,
            text_color=COLOR_TAB_TEXT, corner_radius=0,
            command=self._switch_to_info,
        )
        self._btn_info.grid(row=0, column=1, padx=(0, 0))

        self._content = ctk.CTkFrame(self, fg_color=COLOR_BG)
        self._content.grid(row=1, column=0, sticky="nsew", padx=0, pady=0)
        self._content.grid_columnconfigure(0, weight=1)
        self._content.grid_rowconfigure(0, weight=1)

        self._chat_frame = ctk.CTkFrame(self._content, fg_color=COLOR_BG)
        self._chat_frame.grid_columnconfigure(0, weight=1)
        self._chat_frame.grid_rowconfigure(0, weight=1)

        self._chat_scroll = ScrollableChatFrame(
            self._chat_frame, fg_color=COLOR_BG,
        )
        self._chat_scroll.grid(row=0, column=0, sticky="nsew", padx=4, pady=4)

        self._input_frame = ctk.CTkFrame(
            self._chat_frame, fg_color=COLOR_INPUT_BG, height=44,
        )
        self._input_frame.grid(row=1, column=0, sticky="ew", padx=4, pady=(0, 4))
        self._input_frame.grid_columnconfigure(0, weight=1)

        self._txt_input = ctk.CTkEntry(
            self._input_frame,
            font=(FONT_FAMILY, FONT_SIZES["input"]),
            fg_color=COLOR_BG, text_color=COLOR_AI_TEXT,
            border_color=COLOR_BORDER,
            placeholder_text="Type a message…",
            placeholder_text_color="#666666",
        )
        self._txt_input.grid(row=0, column=0, sticky="ew", padx=(8, 4), pady=6)
        self._txt_input.bind("<Return>", lambda e: self._send_message())

        self._btn_send = ctk.CTkButton(
            self._input_frame, text="Send", width=70,
            font=(FONT_FAMILY, FONT_SIZES["send"]),
            fg_color=COLOR_SEND_BTN, hover_color="#0066CC",
            text_color=COLOR_SEND_TEXT, corner_radius=6,
            command=self._send_message,
        )
        self._btn_send.grid(row=0, column=1, padx=(4, 8), pady=6)

        self._info_frame = ctk.CTkFrame(self._content, fg_color=COLOR_BG)
        self._info_frame.grid_columnconfigure(0, weight=1)
        self._info_frame.grid_rowconfigure(0, weight=1)

        mt5_client = getattr(self._agent, "metatrader_client", None) if self._agent else None
        self._info_scroll = ScrollableInfoFrame(
            self._info_frame, mt5_client=mt5_client,
            fg_color=COLOR_BG,
            scrollbar_button_color=COLOR_TAB_INACTIVE,
            scrollbar_button_hover_color=COLOR_TAB_ACTIVE,
        )
        self._info_scroll.grid(row=0, column=0, sticky="nsew", padx=4, pady=4)

        self._current_tab: str = "chat"
        self._show_tab("chat")

        self.add_message(
            "assistant",
            "Hello! I'm your AI trading assistant. Ask me anything about your "
            "positions, market analysis, or trading strategies.",
        )

    # Tab switching

    def _switch_to_chat(self) -> None:
        self._show_tab("chat")
        self._btn_chat.configure(fg_color=COLOR_TAB_ACTIVE)
        self._btn_info.configure(fg_color=COLOR_TAB_INACTIVE)

    def _switch_to_info(self) -> None:
        self._show_tab("info")
        self._btn_chat.configure(fg_color=COLOR_TAB_INACTIVE)
        self._btn_info.configure(fg_color=COLOR_TAB_ACTIVE)
        self._info_scroll.refresh()

    def _show_tab(self, tab: str) -> None:
        if tab == "chat":
            self._chat_frame.grid(row=0, column=0, sticky="nsew")
            self._info_frame.grid_forget()
        else:
            self._info_frame.grid(row=0, column=0, sticky="nsew")
            self._chat_frame.grid_forget()
        self._current_tab = tab

    # Chat

    def add_message(self, role: str, content: str) -> None:
        ts = datetime.now().strftime("%H:%M:%S")
        self._message_history.append({"role": role, "content": content, "time": ts})
        self._chat_scroll.add_message(role, content, timestamp=ts)

    def _send_message(self) -> None:
        if self._request_pending:
            return

        text = self._txt_input.get().strip()
        if not text:
            return

        self._txt_input.delete(0, "end")
        self.add_message("user", text)

        if self._agent is not None:
            self._request_pending = True
            self._pending_msg = text
            self.add_message("assistant", "Thinking…")
            self._btn_send.configure(state="disabled")

            thread = threading.Thread(target=self._run_agent, daemon=True)
            thread.start()

    def _run_agent(self) -> None:
        try:
            response = self._agent.run(self._pending_msg)
        except Exception as e:
            response = f"Error: {e}"
        self.after(0, self._complete_pending, response)

    def _complete_pending(self, response: str) -> None:
        if not self._request_pending:
            return
        self._request_pending = False

        # Pop placeholder
        if self._message_history and self._message_history[-1]["content"] == "Thinking…":
            self._message_history.pop()

        # Append response
        self._message_history.append(
            {"role": "assistant", "content": response,
             "time": datetime.now().strftime("%H:%M:%S")}
        )

        # Redraw all
        self._chat_scroll.clear()
        for msg in self._message_history:
            self._chat_scroll.add_message(
                msg["role"], msg["content"], timestamp=msg.get("time", "")
            )

        self._btn_send.configure(state="normal")

    def on_close(self) -> None:
        self.destroy()


def launch(
    agent: Optional[Agent] = None,
    title: str = "MetaTrader-AI",
    width: int = 520,
    height: int = 700,
) -> None:
    """Launch the desktop GUI."""
    ctk.set_appearance_mode("Dark")
    ctk.set_default_color_theme("dark-blue")
    app = App(agent=agent, title=title, width=width, height=height)
    app.protocol("WM_DELETE_WINDOW", app.on_close)
    app.mainloop()


if __name__ == "__main__":
    launch()
