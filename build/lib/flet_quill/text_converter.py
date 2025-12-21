from __future__ import annotations

from typing import Union
import json
import os
import re


def delta_from_plain_text(text: str) -> list:
    text = (text or "").replace("\r\n", "\n").replace("\r", "\n")
    if not text.endswith("\n"):
        text += "\n"
    return [{"insert": text}]


def text_from_html_minimal(html: str) -> str:
    try:
        from bs4 import BeautifulSoup  # from beautifulsoup4
    except Exception as e:
        raise RuntimeError(
            "HTML conversion requires 'beautifulsoup4'. Install: pip install beautifulsoup4"
        ) from e

    soup = BeautifulSoup(html or "", "html.parser")

    for br in soup.find_all("br"):
        br.replace_with("\n")

    for tag_name in ("p", "div", "li", "h1", "h2", "h3", "h4", "h5", "h6", "tr"):
        for t in soup.find_all(tag_name):
            t.append("\n")

    text = soup.get_text()
    lines = [ln.rstrip() for ln in text.replace("\r\n", "\n").replace("\r", "\n").split("\n")]

    out = []
    blank_run = 0
    for ln in lines:
        if ln.strip() == "":
            blank_run += 1
            if blank_run <= 2:
                out.append("")
        else:
            blank_run = 0
            out.append(ln)

    return "\n".join(out).strip()


def text_from_pdf_minimal(pdf: Union[str, bytes, bytearray]) -> str:
    try:
        from pypdf import PdfReader
    except Exception as e:
        raise RuntimeError("PDF conversion requires 'pypdf'. Install: pip install pypdf") from e

    if isinstance(pdf, (bytes, bytearray)):
        import io
        reader = PdfReader(io.BytesIO(pdf))
    elif isinstance(pdf, str):
        reader = PdfReader(pdf)
    else:
        raise TypeError("pdf must be a file path (str) or bytes")

    pages_text = []
    for page in reader.pages:
        t = (page.extract_text() or "").replace("\r\n", "\n").replace("\r", "\n").strip()
        if t:
            # Normalize multiple spaces to single space, preserve newlines
            t = re.sub(r' +', ' ', t)
            pages_text.append(t)

    return "\n\n".join(pages_text).strip()


def to_delta_ops(value: Union[list, str, bytes, bytearray, None]) -> list:
    if value is None:
        return delta_from_plain_text("")

    if isinstance(value, list):
        return value

    if isinstance(value, (bytes, bytearray)):
        return delta_from_plain_text(text_from_pdf_minimal(value))

    if isinstance(value, str):
        s = value.strip()
        if not s:
            return delta_from_plain_text("")

        if (s.startswith("[") and s.endswith("]")) or (s.startswith("{") and s.endswith("}")):
            try:
                return json.loads(s)
            except Exception:
                pass

        if s.lower().endswith(".pdf") and os.path.exists(s):
            return delta_from_plain_text(text_from_pdf_minimal(s))

        if "<" in s and ">" in s:
            return delta_from_plain_text(text_from_html_minimal(s))

        return delta_from_plain_text(s)

    raise TypeError("Unsupported text_data type")