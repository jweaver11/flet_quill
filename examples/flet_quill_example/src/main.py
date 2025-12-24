import flet as ft
import os
import sys
import json

# Always use most recent build
src_dir = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "src")
)
if src_dir not in sys.path:
    sys.path.insert(0, src_dir)

from flet_quill import FletQuill


app_data_path = os.getenv("FLET_APP_STORAGE_DATA")


file_path_deltaops = os.path.join(app_data_path, "file_path_delta.json")

# Can convert to these formats
file_path_pdf = os.path.join(app_data_path, "file_path.pdf")
file_path_html = os.path.join(app_data_path, "file_path.html")
file_path_docx = os.path.join(app_data_path, "file_path.docx")
file_path_txt = os.path.join(app_data_path, "file_path.txt")
file_path_rtf = os.path.join(app_data_path, "file_path.rtf")
file_path_md = os.path.join(app_data_path, "file_path.md")


def main(page: ft.Page):

    # Custom save method
    def custom_save_method(delta_ops: list):
        print("Delta data to save: ", delta_ops)    # Doc editor text

    json_text_data = [{"insert": "This is a test json data"}, {"insert": "\n"}]

    
    # Optional: load delta from JSON file
    with open(file_path_deltaops, 'r') as f:
        delta_text_data = json.load(f)

    page.add(
        ft.Container(
            expand=True, alignment=ft.alignment.center, 

            # Set our content as a FletQuill. Styles below give it google docs/ms word look
            content=FletQuill(

                # File path string you want to pass in
                file_path=file_path_deltaops,    

                # Set border visibility and width
                border_visible=True,
                border_width=1.0,       # Defaults to 1.0

                # Set paddings around the editor. Defaults to 10.0
                padding_left=72.0,
                padding_top=72.0,
                padding_right=72.0,
                padding_bottom=72.0,

                # Paper like ratio
                aspect_ratio=8.5/11.0,

                # Show divider below toolbar
                show_toolbar_divider=False,  
                
                # Placeholder text
                placeholder_text="Start typing your document here...",
            ),
        ),
    )


ft.app(main)
