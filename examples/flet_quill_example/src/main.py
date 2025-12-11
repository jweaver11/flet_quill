import flet as ft
import os
import sys

# add project src/ folder to sys.path so we use the local custom_draggable
src_dir = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "src")
)
if src_dir not in sys.path:
    sys.path.insert(0, src_dir)

from flet_quill import FletQuill


def main(page: ft.Page):
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER

    page.add(
        ft.Container(
            expand=True,
            alignment = ft.alignment.center, 
            content=FletQuill(
                #tooltip="My new FletQuill Control tooltip",
                body_text = "My new FletQuill Flet Control", 
            ),
        ),
    )


ft.app(main)
