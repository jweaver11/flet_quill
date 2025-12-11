from enum import Enum
from typing import Any, Optional

from flet.core.constrained_control import ConstrainedControl
from flet.core.control import OptionalNumber

class FletQuill(ConstrainedControl):
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
        body_text: Optional[str] = None,
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
        #cc = ConstrainedControl()

        self.body_text = body_text

    def _get_control_name(self):
        return "flet_quill"

    # value
    @property
    def body_text(self):
        """
        Value property description.
        """
        return self._get_attr("body_text")

    @body_text.setter
    def body_text(self, value):
        self._set_attr("body_text", value)
