from enum import Enum
from typing import Any, Optional

from flet.core.constrained_control import ConstrainedControl
from flet.core.control import OptionalNumber, Control

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
        
        # Allowed file types (WIP)
        self.allowed_file_types =  [".docx", ".txt", ".html", ".pdf"]

    def _get_control_name(self):
        return "flet_quill"

    # value
    @property
    def file_path(self):
        """
        Value property description.
        """
        return self._get_attr("file_path")

    @file_path.setter
    def file_path(self, value):
        self._set_attr("file_path", value)

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
