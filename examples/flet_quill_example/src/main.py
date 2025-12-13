import flet as ft
import os
import sys

# Always use most recent build
src_dir = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "src")
)
if src_dir not in sys.path:
    sys.path.insert(0, src_dir)

from flet_quill import FletQuill


app_data_path = os.getenv("FLET_APP_STORAGE_DATA")
file_path = os.path.join(app_data_path, "file_path.json")


def main(page: ft.Page):
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER



    page.add(
        ft.Container(
            expand=True,
            alignment = ft.alignment.center, 
            content=FletQuill(
                #tooltip="My new FletQuill Control tooltip",
                #body_text = "My new FletQuill Flet Control", 
                file_path=file_path
            ),
        ),
    )


ft.app(main)
