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
        allowed_file_types=None,
        file_path: Optional[str] = None,
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

        self.file_path = file_path
        self.allowed_file_types =  [".docx", ".txt", ".html", ".pdf",]

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
