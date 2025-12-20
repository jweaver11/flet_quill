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


    # Custom save method
    def save_to_db(delta_ops: list):
        print("Called save to db method")
        print("Delta data to save: ", delta_ops)    # Doc editor text



    page.add(
        ft.Container(
            expand=True,
            alignment = ft.alignment.center, 
            content=FletQuill(

                # File path string you want to pass in
                file_path=file_path,    

                # Inital text data
                #text_data=[{"insert": "Hello"}, {"insert": "\n"}],
                #save_method=save_to_db,

                # Set border visibility and width
                border_visible=True,
                border_width=1.0,       # Defaults to 1.0

                # Set paddings around the editor. Defaults to 10.0
                padding_left=72.0,
                padding_top=72.0,
                padding_right=72.0,
                padding_bottom=72.0,

                aspect_ratio=8.5/11.0,  # paper-like ratio

                show_toolbar_divider=False,  # Show divider below toolbar
                #use_zoom_factor=False,      # Use zoom factor when using aspect ratio (defaults True)
                #center_toolbar=True,   # Center the toolbar (defaults False/left)
                #scroll_toolbar=True,    # Scroll toolbar horizontally instead of wrapping

                #show_page_breaks=True,    # Show page breaks in the editor
                # Custom font sizes for the font-size dropdown
                #font_sizes=[8, 9, 10, 11, 12, 14, 16, 18, 24, 32, 64],
            ),
        ),
    )


ft.app(main)
