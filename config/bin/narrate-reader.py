#!/usr/bin/env python3
"""Chunk long prose and play it through one loaded MLX TTS model."""

from __future__ import annotations

import os
import re
import signal
import subprocess
import sys
import tempfile
from collections.abc import Iterable
from pathlib import Path


SENTENCE_RE = re.compile(r".+?(?:[.!?…]+[\"'”’)]*(?=\s|$)|$)", re.DOTALL)


def _split_words(text: str, max_chars: int) -> list[str]:
    """Split oversized sentences without dropping or reordering words."""
    chunks: list[str] = []
    current: list[str] = []
    current_length = 0

    for word in text.split():
        added = len(word) + (1 if current else 0)
        if current and current_length + added > max_chars:
            chunks.append(" ".join(current))
            current = [word]
            current_length = len(word)
        else:
            current.append(word)
            current_length += added

    if current:
        chunks.append(" ".join(current))
    return chunks


def _sentences(paragraph: str) -> list[str]:
    sentences = [match.group(0).strip() for match in SENTENCE_RE.finditer(paragraph)]
    return [sentence for sentence in sentences if sentence]


def _pack_sentences(sentences: Iterable[str], max_chars: int) -> list[str]:
    chunks: list[str] = []
    current = ""

    for sentence in sentences:
        if len(sentence) > max_chars:
            if current:
                chunks.append(current)
                current = ""
            chunks.extend(_split_words(sentence, max_chars))
            continue

        candidate = f"{current} {sentence}".strip()
        if current and len(candidate) > max_chars:
            chunks.append(current)
            current = sentence
        else:
            current = candidate

    if current:
        chunks.append(current)
    return chunks


def chunk_text(text: str, max_chars: int = 700) -> list[str]:
    """Create natural paragraph/sentence chunks below the model token ceiling."""
    normalized = text.replace("\r\n", "\n").replace("\r", "\n").strip()
    if not normalized:
        return []

    paragraphs = re.split(r"\n\s*\n+", normalized)
    chunks: list[str] = []
    for paragraph in paragraphs:
        # A prose paragraph may be hard-wrapped in the source file. Join those
        # display lines before finding sentence boundaries.
        paragraph = " ".join(line.strip() for line in paragraph.splitlines()).strip()
        if not paragraph:
            continue
        chunks.extend(_pack_sentences(_sentences(paragraph), max_chars))
    return chunks


def _handle_termination(signum: int, _frame: object) -> None:
    raise SystemExit(128 + signum)


def main() -> int:
    text = sys.stdin.read()
    max_chars = int(os.environ.get("NARRATE_CHUNK_CHARS", "700"))
    max_tokens = int(os.environ.get("NARRATE_MAX_TOKENS", "1200"))
    model_name = os.environ["NARRATE_MODEL"]
    voice = os.environ.get("NARRATE_VOICE", "Aiden")
    language = os.environ.get("NARRATE_LANGUAGE", "English")

    chunks = chunk_text(text, max_chars=max_chars)
    if not chunks:
        print("narrate: no input text", file=sys.stderr)
        return 1

    # Import MLX only after validating input. This also keeps chunk_text usable
    # in lightweight tests on machines without Metal access.
    import numpy as np
    from mlx_audio.audio_io import write as audio_write
    from mlx_audio.tts.utils import load_model

    model = load_model(model_path=model_name)
    get_speakers = getattr(model, "get_supported_speakers", lambda: [])
    supported_speakers = get_speakers()
    supported = {name.lower() for name in supported_speakers}
    if supported and voice.lower() not in supported:
        available = ", ".join(supported_speakers)
        print(f"narrate: unsupported voice {voice!r}; available: {available}", file=sys.stderr)
        return 1

    paragraph_pause = np.zeros(int(model.sample_rate * 0.25), dtype=np.float32)

    # Keep the playback backend that proved reliable in the original narrator.
    # While afplay reads the current WAV, Qwen prepares the next one. This keeps
    # one model resident, avoids the model's long-input token ceiling, and
    # normally hides most of the generation gap between chunks.
    with tempfile.TemporaryDirectory(prefix="narrate.") as workdir:
        player: subprocess.Popen[bytes] | None = None
        for index, chunk in enumerate(chunks, start=1):
            print(f"chunk {index}/{len(chunks)}", flush=True)
            audio_parts = []
            results = model.generate(
                text=chunk,
                voice=voice,
                lang_code=language,
                max_tokens=max_tokens,
                temperature=0.7,
                top_k=50,
                top_p=0.9,
                repetition_penalty=1.1,
                stream=False,
                verbose=False,
            )
            for result in results:
                audio_parts.append(np.asarray(result.audio, dtype=np.float32))

            if not audio_parts:
                raise RuntimeError(f"chunk {index} produced no audio")

            audio = np.concatenate(audio_parts)
            if index < len(chunks):
                audio = np.concatenate((audio, paragraph_pause))
            wav = Path(workdir, f"chunk-{index:04d}.wav")
            audio_write(str(wav), audio, model.sample_rate)

            if player is not None and player.wait() != 0:
                raise RuntimeError("afplay stopped unexpectedly")
            player = subprocess.Popen(["/usr/bin/afplay", str(wav)])

        if player is not None and player.wait() != 0:
            raise RuntimeError("afplay stopped unexpectedly")
    return 0


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, _handle_termination)
    signal.signal(signal.SIGINT, _handle_termination)
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130) from None
