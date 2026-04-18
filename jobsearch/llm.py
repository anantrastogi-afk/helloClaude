"""Thin wrapper around the Anthropic client.

Mirrors the style in gmail_summary_agent.py so both tools stay consistent.
Default models:
  - REASONING: claude-opus-4-7 (match scoring, materials, interview coaching)
  - CLASSIFY:  claude-sonnet-4-6 (parsing, email classification)
"""

from typing import Any

import anthropic


REASONING_MODEL = "claude-opus-4-7"
CLASSIFY_MODEL = "claude-sonnet-4-6"


def _client() -> anthropic.Anthropic:
    return anthropic.Anthropic()


def complete(
    system: str,
    user: str | list[dict[str, Any]],
    model: str = REASONING_MODEL,
    max_tokens: int = 2048,
    temperature: float = 0.2,
) -> str:
    messages: list[dict[str, Any]]
    if isinstance(user, str):
        messages = [{"role": "user", "content": user}]
    else:
        messages = [{"role": "user", "content": user}]

    msg = _client().messages.create(
        model=model,
        max_tokens=max_tokens,
        temperature=temperature,
        system=system,
        messages=messages,
    )
    return "".join(block.text for block in msg.content if block.type == "text")


def complete_multiturn(
    system: str,
    history: list[dict[str, Any]],
    model: str = REASONING_MODEL,
    max_tokens: int = 1024,
    temperature: float = 0.4,
) -> str:
    msg = _client().messages.create(
        model=model,
        max_tokens=max_tokens,
        temperature=temperature,
        system=system,
        messages=history,
    )
    return "".join(block.text for block in msg.content if block.type == "text")
