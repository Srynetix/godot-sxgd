extends CanvasLayer
class_name SxDebugTools
## Global debug tools.

const _NORMAL_FONT := preload("res://addons/sxgd/assets/fonts/OfficeCodePro-Regular.otf")
const _BOLD_FONT := preload("res://addons/sxgd/assets/fonts/OfficeCodePro-Bold.otf")
const _CODE_FONT := preload("res://addons/sxgd/assets/fonts/Inconsolata-Regular.ttf")

## Panel type to display.
enum PanelType {
    ## Debug info.
    DEBUG_INFO,
    ## Log.
    LOG,
    ## Node tracer.
    NODE_TRACER,
    ## Scene tree dump.
    SCENE_TREE_DUMP,
    ## Console.
    CONSOLE,
}

## Should the panel be visible on startup?
@export var visible_on_startup := false
## Panel to show on startup.
@export var panel_on_startup := PanelType.DEBUG_INFO

@onready var _visible := visible_on_startup
@onready var _current_panel := panel_on_startup

var _main_panel: Panel
var _log_panel: SxLogPanel
var _node_tracer: SxNodeTracerSystem
var _scene_tree_dump: MarginContainer
var _debug_console: SxDebugConsole
var _debug_info: SxDebugInfo

## Setup a global instance.
static func setup_global_instance(tree: SceneTree):
    if !tree.root.has_node("SxDebugTools"):
        tree.root.call_deferred("add_child", SxDebugTools.new())
        await tree.process_frame

## Get a global instance.
static func get_global_instance(tree: SceneTree) -> SxDebugTools:
    return tree.root.get_node("SxDebugTools")

## Hide the debug panel.
func hide_tools() -> void:
    _hide_panels()
    _main_panel.visible = false
    _visible = false

## Show the debug panel.
func show_tools() -> void:
    _main_panel.visible = true
    _visible = true
    _show_panel(_current_panel)

## Toggle the debug panel.
func toggle() -> void:
    if _visible:
        hide_tools()
    else:
        show_tools()

## Show a specific panel.
func show_specific_panel(panel_type: PanelType) -> void:
    _show_panel(panel_type)

func _init() -> void:
    name = "SxDebugTools"

func _build_ui() -> void:
    var box := StyleBoxEmpty.new()

    layer = 4

    var _main_panel_stylebox := StyleBoxFlat.new()
    _main_panel_stylebox.bg_color = SxColor.with_alpha_f(Color.BLACK, 0.5)

    _main_panel = Panel.new()
    _main_panel.name = "Panel"
    _main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _main_panel.add_theme_stylebox_override("panel", _main_panel_stylebox)
    add_child(_main_panel)

    _debug_info = SxDebugInfo.new()
    _main_panel.add_child(_debug_info)

    var hbox_container := HBoxContainer.new()
    hbox_container.name = "HBox"
    hbox_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hbox_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _main_panel.add_child(hbox_container)

    var container := Control.new()
    hbox_container.name = "Main"
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox_container.add_child(container)

    _log_panel = SxLogPanel.new()
    container.add_child(_log_panel)

    _debug_console = SxDebugConsole.new()
    container.add_child(_debug_console)

    _node_tracer = SxNodeTracerSystem.new()
    container.add_child(_node_tracer)

    _scene_tree_dump = MarginContainer.new()
    _scene_tree_dump.name = "SceneTreeDumpContainer"
    _scene_tree_dump.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _scene_tree_dump.add_theme_constant_override("margin_right", 20)
    _scene_tree_dump.add_theme_constant_override("margin_top", 20)
    _scene_tree_dump.add_theme_constant_override("margin_left", 20)
    _scene_tree_dump.add_theme_constant_override("margin_bottom", 20)
    container.add_child(_scene_tree_dump)

    var scene_tree_hbox_container := HBoxContainer.new()
    scene_tree_hbox_container.name = "HBox"
    _scene_tree_dump.add_child(scene_tree_hbox_container)

    var local_scene_tree_container := VBoxContainer.new()
    local_scene_tree_container.name = "LocalTreeContainer"
    local_scene_tree_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    local_scene_tree_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scene_tree_hbox_container.add_child(local_scene_tree_container)

    var local_scene_tree_title := Label.new()
    local_scene_tree_title.name = "Title"
    local_scene_tree_title.add_theme_font_override("font", _BOLD_FONT)
    local_scene_tree_title.text = "Local tree"
    local_scene_tree_container.add_child(local_scene_tree_title)

    var local_scene_tree := Tree.new()
    local_scene_tree.name = "Tree"
    local_scene_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
    local_scene_tree.add_theme_constant_override("draw_guides", 0)
    local_scene_tree.add_theme_constant_override("draw_relationship_lines", 1)
    local_scene_tree.add_theme_font_override("font", _CODE_FONT)
    local_scene_tree.add_theme_font_size_override("font_size", 13)
    local_scene_tree.add_theme_color_override("font_outline_color", Color.BLACK)
    local_scene_tree.add_theme_constant_override("outline_size", 6)
    local_scene_tree.add_theme_stylebox_override("panel", box)
    local_scene_tree_container.add_child(local_scene_tree)

    var right_container := MarginContainer.new()
    right_container.name = "RightContainer"
    right_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    right_container.add_theme_constant_override("margin_right", 10)
    right_container.add_theme_constant_override("margin_top", 10)
    right_container.add_theme_constant_override("margin_left", 10)
    right_container.add_theme_constant_override("margin_bottom", 10)
    hbox_container.add_child(right_container)

    var right_title := Label.new()
    right_title.name = "Title"
    right_title.size_flags_horizontal = Control.SIZE_SHRINK_END
    right_title.size_flags_vertical = 0
    right_title.add_theme_font_override("font", _BOLD_FONT)
    right_title.add_theme_color_override("font_outline_color", Color.BLACK)
    right_title.text = "Debug Tools"
    right_container.add_child(right_title)

    var right_label := Label.new()
    right_label.name = "Instructions"
    right_label.size_flags_horizontal = Control.SIZE_SHRINK_END
    right_label.size_flags_vertical = Control.SIZE_SHRINK_END
    right_label.add_theme_font_override("font", _NORMAL_FONT)
    right_label.add_theme_color_override("font_outline_color", Color.BLACK)
    right_label.add_theme_font_size_override("font_size", 12)
    right_label.text = (
        "` - Show console\n"
        + "F3 - Toggle mouse visibility\n"
        + "F7 - Show scene tree dumps\n"
        + "F9 - Show node traces\n"
        + "F10 - Show logs\n"
        + "F11 - Show stats\n"
        + "F12 - Toggle panel"
    )
    right_container.add_child(right_label)

func _ready() -> void:
    _build_ui()

    _debug_info.set_visibility(false)
    _main_panel.visible = false
    _node_tracer.visible = false
    _log_panel.visible = false
    _debug_console.visible = false
    _scene_tree_dump.visible = false

    if visible_on_startup:
        show_tools()

func _show_panel(panel_type: PanelType) -> void:
    _current_panel = panel_type
    _hide_panels()

    match panel_type:
        PanelType.DEBUG_INFO:
            _debug_info.set_visibility(true)
        PanelType.LOG:
            _log_panel.visible = true
        PanelType.NODE_TRACER:
            _node_tracer.visible = true
        PanelType.SCENE_TREE_DUMP:
            _show_scene_tree_dump()
        PanelType.CONSOLE:
            _debug_console.visible = true
            _debug_console.focus_input()

func _show_scene_tree_dump() -> void:
    _scene_tree_dump.visible = true
    var local_tree := _scene_tree_dump.get_node("HBox/LocalTreeContainer/Tree") as Tree
    _build_node_tree(local_tree, get_tree().root)

func _build_node_tree(tree: Tree, node: Node) -> void:
    tree.clear()
    var root := tree.create_item()
    _build_node_tree_item(tree, root, node)

func _build_node_tree_child(tree: Tree, parent: TreeItem, node: Node) -> void:
    var item := tree.create_item(parent)
    _build_node_tree_item(tree, item, node)

func _build_node_tree_item(tree: Tree, item: TreeItem, node: Node) -> void:
    item.set_text(0, "%s (%s)" % [node.name, node.get_class()])
    for child in node.get_children():
        _build_node_tree_child(tree, item, child)

func _hide_panels() -> void:
    _debug_info.set_visibility(false)
    _log_panel.visible = false
    _node_tracer.visible = false
    _scene_tree_dump.visible = false
    _debug_console.visible = false

func _input(event: InputEvent):
    if event is InputEventKey:
        if event.pressed && event.physical_keycode == KEY_F12:
            toggle()

        elif event.pressed && event.physical_keycode == KEY_QUOTELEFT && _visible:
            # Do not bubble up the key.
            get_viewport().set_input_as_handled()
            _show_panel(PanelType.CONSOLE)

        elif event.pressed && event.physical_keycode == KEY_F7 && _visible:
            _show_panel(PanelType.SCENE_TREE_DUMP)

        elif event.pressed && event.physical_keycode == KEY_F9 && _visible:
            _show_panel(PanelType.NODE_TRACER)

        elif event.pressed && event.physical_keycode == KEY_F10 && _visible:
            _show_panel(PanelType.LOG)

        elif event.pressed && event.physical_keycode == KEY_F11 && _visible:
            _show_panel(PanelType.DEBUG_INFO)

        elif event.pressed && event.physical_keycode == KEY_F5 && _visible:
            get_tree().reload_current_scene()

        elif event.pressed && event.physical_keycode == KEY_F2 && _visible:
            get_tree().paused = !get_tree().paused

        elif event.pressed && event.physical_keycode == KEY_F3 && _visible:
            if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            else:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
