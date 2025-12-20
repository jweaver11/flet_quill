from enum import Enum
from typing import Any, Optional, Callable
import json

from flet.core.constrained_control import ConstrainedControl
from flet.core.control import OptionalNumber, Control
from flet.core.event import Event


class FletQuill(Control):
    """
    FletQuill Control description.
    """

    def __init__(
        self,
        #
        # Control
        #
        opacity: OptionalNumber = None,
        tooltip: Optional[str] = None,
        visible: Optional[bool] = None,
        data: Any = None,
        #
        # ConstrainedControl
        #
        left: OptionalNumber = None,
        top: OptionalNumber = None,
        right: OptionalNumber = None,
        bottom: OptionalNumber = None,
        expand: bool = True,
        #
        # FletQuill specific
        #
        file_path: Optional[str] = None,
        border_visible: bool = False,
        border_width: float = 1.0,
        padding_left: float = 10.0,
        padding_top: float = 10.0,
        padding_right: float = 10.0,
        padding_bottom: float = 10.0,
        aspect_ratio: float = None,
        show_toolbar_divider: bool = True,
        center_toolbar: bool = False,
        show_page_breaks: bool = False,
        # Text Data
        text_data: Optional[list] = None,
        save_method: Optional[Callable[[list], None]] = None,
    ):
        ConstrainedControl.__init__(
            self,
            tooltip=tooltip,
            opacity=opacity,
            visible=visible,
            data=data,
            left=left,
            top=top,
            right=right,
            bottom=bottom,
            expand=expand,
        )

        # Set the file path attribute
        self.file_path: str = file_path

        # Set our border visibility and width
        self.border_visible = border_visible
        self.border_width = border_width

        # Set padding attributes
        self.padding_left = padding_left
        self.padding_top = padding_top
        self.padding_right = padding_right
        self.padding_bottom = padding_bottom

        # Set the aspect ratio usage
        self.aspect_ratio = aspect_ratio

        # Center toolbar option
        self.show_toolbar_divider = show_toolbar_divider
        self.center_toolbar = center_toolbar

        # Show page breaks option
        self.show_page_breaks = show_page_breaks

        # Allowed file types (WIP)
        self.allowed_file_types = [".docx", ".txt", ".html", ".pdf"]

        # ---- New: initial content + custom save callback ----
        self._save_method: Optional[Callable[[list], None]] = None

        if text_data is not None:
            self.text_data = text_data  # stored as JSON string attr for Flutter

        self.save_method = save_method  # enables/disables save-to-event mode

    def _get_control_name(self):
        return "flet_quill"

    # file_path
    @property
    def file_path(self):
        return self._get_attr("file_path")

    @file_path.setter
    def file_path(self, value):
        self._set_attr("file_path", value)

    # text_data (JSON string attribute consumed by Flutter)
    @property
    def text_data(self) -> Optional[list]:
        v = self._get_attr("text_data")
        if not v:
            return None
        try:
            return json.loads(v)
        except Exception:
            return None

    @text_data.setter
    def text_data(self, value: Optional[list]):
        if value is None:
            self._set_attr("text_data", None)
            return
        self._set_attr("text_data", json.dumps(value))

    # save_method (Python-side callback; Flutter triggers "save" event)
    @property
    def save_method(self) -> Optional[Callable[[list], None]]:
        return self._save_method

    @save_method.setter
    def save_method(self, cb: Optional[Callable[[list], None]]):
        self._save_method = cb

        # Let Flutter know whether it should write to file_path or emit an event.
        self._set_attr("save_to_event", cb is not None)

        # Register/unregister handler.
        if cb is not None:
            self._add_event_handler("save", self.__handle_save_event)
        else:
            self._add_event_handler("save", None)

    def __handle_save_event(self, e: Event):
        if self._save_method is None:
            return
        try:
            payload = json.loads(e.data) if e.data else []
        except Exception:
            payload = []
        self._save_method(payload)

    # border_visible
    @property
    def border_visible(self):
        return self._get_attr("border_visible", data_type=bool)

    @border_visible.setter
    def border_visible(self, value: bool):
        self._set_attr("border_visible", value)

    # border_width
    @property
    def border_width(self):
        return self._get_attr("border_width", data_type=float)

    @border_width.setter
    def border_width(self, value: float):
        self._set_attr("border_width", value)

    # padding_left
    @property
    def padding_left(self):
        return self._get_attr("padding_left", data_type=float)

    @padding_left.setter
    def padding_left(self, value: float):
        self._set_attr("padding_left", value)

    # padding_top
    @property
    def padding_top(self):
        return self._get_attr("padding_top", data_type=float)

    @padding_top.setter
    def padding_top(self, value: float):
        self._set_attr("padding_top", value)

    # padding_right
    @property
    def padding_right(self):
        return self._get_attr("padding_right", data_type=float)

    @padding_right.setter
    def padding_right(self, value: float):
        self._set_attr("padding_right", value)

    # padding_bottom
    @property
    def padding_bottom(self):
        return self._get_attr("padding_bottom", data_type=float)

    @padding_bottom.setter
    def padding_bottom(self, value: float):
        self._set_attr("padding_bottom", value)

    # aspect_ratio
    @property
    def aspect_ratio(self):
        return self._get_attr("aspect_ratio", data_type=float)

    @aspect_ratio.setter
    def aspect_ratio(self, value: float):
        self._set_attr("aspect_ratio", value)

    # show_toolbar_divider
    @property
    def show_toolbar_divider(self):
        return self._get_attr("show_toolbar_divider", data_type=bool)

    @show_toolbar_divider.setter
    def show_toolbar_divider(self, value: bool):
        self._set_attr("show_toolbar_divider", value)

    # center_toolbar
    @property
    def center_toolbar(self):
        return self._get_attr("center_toolbar", data_type=bool)

    @center_toolbar.setter
    def center_toolbar(self, value: bool):
        self._set_attr("center_toolbar", value)

    # show_page_breaks
    @property
    def show_page_breaks(self):
        return self._get_attr("show_page_breaks", data_type=bool)

    @show_page_breaks.setter
    def show_page_breaks(self, value: bool):
        self._set_attr("show_page_breaks", value)
