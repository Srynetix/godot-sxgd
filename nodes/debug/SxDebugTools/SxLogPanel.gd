extends MarginContainer
class_name SxLogPanel
## Log panel, display scrollable logs.

const _NORMAL_FONT = preload("res://addons/sxgd/assets/fonts/OfficeCodePro-Regular.otf")
const _BOLD_FONT = preload("res://addons/sxgd/assets/fonts/OfficeCodePro-Bold.otf")

## Max messages to display.
@export var max_messages := 100

var _last_message: SxLog.LogMessage
var _template: RichTextLabel
var _container: VBoxContainer

## Toggle the log panel.
func toggle():
    visible = !visible

func _ready():
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_theme_constant_override("margin_right", 10)
    add_theme_constant_override("margin_top", 10)
    add_theme_constant_override("margin_left", 10)
    add_theme_constant_override("margin_bottom", 10)

    var scroll_container := ScrollContainer.new()
    add_child(scroll_container)

    _container = VBoxContainer.new()
    _container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _container.alignment = BoxContainer.ALIGNMENT_END
    scroll_container.add_child(_container)

    _template = RichTextLabel.new()
    _template.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
    _template.add_theme_font_override("bold_font", _BOLD_FONT)
    _template.add_theme_font_override("normal_font", _NORMAL_FONT)
    _template.add_theme_font_size_override("bold_font_size", 12)
    _template.add_theme_font_size_override("normal_font_size", 12)
    _template.add_theme_color_override("font_outline_color", Color.BLACK)
    _template.add_theme_constant_override("outline_size", 3)
    _template.bbcode_enabled = true
    _template.text = "Hello."
    _template.fit_content = true
    _template.scroll_active = false

    _update_text()

func _process(delta: float):
    _update_text()

func _update_text():
    for entry in SxLog.pop_messages():
        var message := entry as SxLog.LogMessage
        var logger_name := message.logger_name
        if logger_name == "":
            logger_name = "root"

        var text := "[b][color=yellow][%0.3f][/color][/b] " % message.time
        text += "[b][color=yellow][%s][/color][/b] " % SxLog._LogUtils.level_to_string(message.level).to_upper()
        text += "[b][color=green][%s][/color][/b] " % message.logger_name

        if message.level == SxLog.LogLevel.ERROR:
            text += "[color=red]%s[/color]" % message.message
        else:
            text += message.message

        var block := _template.duplicate()
        block.text = text
        _container.add_child(block)

        # Remove old messages
        while _container.get_child_count() >= max_messages:
            var old := _container.get_child(0)
            old.queue_free()
            _container.remove_child(old)
