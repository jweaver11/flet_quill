from enum import Enum
from typing import Any, Optional, Callable, Union
import json
import os

from flet.core.constrained_control import ConstrainedControl
from flet.core.control import OptionalNumber, Control
from flet.core.event import Event


def _delta_from_plain_text(text: str) -> list:
    """
    Convert plain text to a minimal Quill Delta ops list.
    Quill documents should end with a newline.
    """
    if text is None:
        text = ""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    if not text.endswith("\n"):
        text += "\n"
    return [{"insert": text}]


def _text_from_html_minimal(html: str) -> str:
    """
    Minimal HTML -> plain text conversion with basic block newlines.
    Keeps no styling; produces readable paragraphs.
    """
    try:
        from bs4 import BeautifulSoup  # pip install beautifulsoup4
    except Exception as e:
        raise RuntimeError(
            "HTML conversion requires 'beautifulsoup4'. Install with: pip install beautifulsoup4"
        ) from e

    soup = BeautifulSoup(html or "", "html.parser")

    # Convert <br> to newlines
    for br in soup.find_all("br"):
        br.replace_with("\n")

    # Add newlines after common block tags
    for tag_name in ("p", "div", "li", "h1", "h2", "h3", "h4", "h5", "h6", "tr"):
        for t in soup.find_all(tag_name):
            t.append("\n")

    text = soup.get_text()
    # Normalize excessive blank lines a bit
    lines = [ln.rstrip() for ln in text.replace("\r\n", "\n").replace("\r", "\n").split("\n")]
    # Keep paragraph spacing, but collapse 3+ blank lines -> 2
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


def _text_from_pdf_minimal(pdf: Union[str, bytes, bytearray]) -> str:
    """
    Minimal PDF -> plain text extraction (formatting/layout lost).
    Accepts a file path or raw PDF bytes.
    """
    try:
        from pypdf import PdfReader  # pip install pypdf
    except Exception as e:
        raise RuntimeError(
            "PDF conversion requires 'pypdf'. Install with: pip install pypdf"
        ) from e

    if isinstance(pdf, (bytes, bytearray)):
        import io
        reader = PdfReader(io.BytesIO(pdf))
    elif isinstance(pdf, str):
        # treat as a file path
        reader = PdfReader(pdf)
    else:
        raise TypeError("pdf must be a file path (str) or bytes")

    pages_text = []
    for page in reader.pages:
        t = page.extract_text() or ""
        t = t.replace("\r\n", "\n").replace("\r", "\n").strip()
        if t:
            pages_text.append(t)

    # Separate pages with blank line
    return "\n\n".join(pages_text).strip()