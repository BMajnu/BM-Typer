# MagicInput.py
# Modern AI-powered input interface with image analysis capabilities

import os
import sys
import shutil
import tempfile
import urllib.request
import tkinter as tk
from tkinter import ttk, filedialog, scrolledtext, messagebox
from PIL import Image, ImageTk, ImageGrab
import datetime
import platform
import threading
from typing import Optional, Any, Sequence, cast
import time
import re
import json
from tkinterdnd2 import TkinterDnD, DND_FILES
from google import genai
from google.genai import types
import pystray
import ctypes
from ctypes import wintypes
from io import BytesIO

# ------------------------------------------------------------------ THEME SETTINGS
class Theme:
    """Modern theme system with clean design principles."""

    @staticmethod
    def dark():
        """Modern dark theme with refined colors."""
        return {
            "bg_primary": "#0F0F23",         # Deep navy background
            "bg_secondary": "#1A1A2E",       # Slightly lighter panels
            "bg_tertiary": "#16213E",        # Input backgrounds
            "bg_accent": "#0E4B99",          # Accent panels
            "bg_header": "#1A1A2E",          # Header background
            "text_primary": "#FFFFFF",       # Pure white text
            "text_secondary": "#A0A0B8",     # Muted text
            "text_tertiary": "#6C6C8A",      # Subtle text
            "fg_header": "#FFFFFF",          # Header text color
            "accent_blue": "#3B82F6",        # Primary blue
            "accent_purple": "#8B5CF6",      # Secondary purple
            "accent_green": "#10B981",       # Success green
            "accent_red": "#EF4444",         # Error red
            "accent_orange": "#F59E0B",      # Warning orange
            "accent_primary": "#8B5CF6",     # Primary accent color
            "accent_secondary": "#10B981",   # Secondary accent color
            "button_danger": "#EF4444",      # Danger button color
            "button_secondary": "#1A1A2E",   # Secondary button color
            "hover_primary": "#A855F7",      # Primary hover color
            "hover_secondary": "#2D2D44",    # Secondary hover color
            "hover_danger": "#F87171",       # Danger hover color
            "border": "#2D2D44",             # Subtle borders
            "shadow": "#000000",             # Shadows
            "gradient_start": "#1A1A2E",     # Gradient effects
            "gradient_end": "#16213E",
        }

    @staticmethod
    def light():
        """Modern light theme with clean aesthetics."""
        return {
            "bg_primary": "#FAFAFA",         # Clean white background
            "bg_secondary": "#F5F5F7",       # Light gray panels
            "bg_tertiary": "#FFFFFF",        # Pure white inputs
            "bg_accent": "#E8F2FF",          # Light blue accent
            "bg_header": "#F5F5F7",          # Header background
            "text_primary": "#1D1D1F",       # Almost black text
            "text_secondary": "#6E6E73",     # Gray text
            "text_tertiary": "#8E8E93",      # Light gray text
            "fg_header": "#1D1D1F",          # Header text color
            "accent_blue": "#007AFF",        # iOS blue
            "accent_purple": "#AF52DE",      # iOS purple
            "accent_green": "#34C759",       # iOS green
            "accent_red": "#FF3B30",         # iOS red
            "accent_orange": "#FF9500",      # iOS orange
            "accent_primary": "#AF52DE",     # Primary accent color
            "accent_secondary": "#34C759",   # Secondary accent color
            "button_danger": "#FF3B30",      # Danger button color
            "button_secondary": "#F5F5F7",   # Secondary button color
            "hover_primary": "#C77DFF",      # Primary hover color
            "hover_secondary": "#E8E8EA",    # Secondary hover color
            "hover_danger": "#FF6B6B",       # Danger hover color
            "border": "#D1D1D6",             # Light borders
            "shadow": "#00000020",           # Light shadows
            "gradient_start": "#F5F5F7",     # Light gradients
            "gradient_end": "#E8E8EA",
        }

    @staticmethod
    def get_current():
        """Get current theme based on system preferences."""
        return Theme.dark()  # Default to dark for modern look


class InputPopup:
    """A small, centred popup window that lets the user attach images and enter text/code."""

    CANVAS_HEIGHT = 160

    def __init__(self, root: tk.Tk):
        self.root = root
        # Default to dark theme
        self.current_theme = Theme.dark()
        self.is_dark_theme = True
        # App logo emoji
        self.app_icon_emoji = '🔮'
        self._configure_window()
        self._create_widgets()
        self._layout_widgets()
        self._enable_dnd()

        # Style for ttk widgets
        style = ttk.Style()
        style.configure("TLabelframe", background=self.current_theme["bg_primary"])
        style.configure("TLabelframe.Label", background=self.current_theme["bg_primary"], foreground=self.current_theme["text_secondary"])

        # Re-apply frameless after restore from minimize
        self.root.bind("<Map>", self._restore_override)

        # Runtime data
        self.image_paths: list[str] = []
        # Store images fully in-memory (no disk paths). Each item: {"bytes": bytes, "name": str}
        self.images: list[dict[str, Any]] = []
        self.current_index = 0
        self.current_photo: ImageTk.PhotoImage | None = None
        self.temp_dir = tempfile.mkdtemp()
        self.app_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
        # Folder where all attachments and prompt logs are stored (hidden dot-folder)
        self.attachments_dir = os.path.join(self.app_dir, "MagicInput")
        os.makedirs(self.attachments_dir, exist_ok=True)
        # Debug log path
        self.log_path = os.path.join(self.attachments_dir, "debug.log")
        # Legacy/expected log filename for user visibility
        self.legacy_log_path = os.path.join(self.attachments_dir, "magicinput.log")
        # Prompt log paths
        self.prompt_log_path = os.path.join(self.attachments_dir, "MagicInput Prompt.txt")
        self.archive_path = os.path.join(self.attachments_dir, "Prompts Archive.txt")
        # Waiting placeholder text (keep wording as requested)
        self.waiting_placeholder = "sill waiting form user's prompt so run the command \"timeout 30\"."
        # Config file path for API keys
        self.config_path = os.path.join(self.app_dir, "MagicInput", "config.json")
        self.api_key: str | None = None
        # Multiple Gemini API keys support
        self.api_keys: list[str] = []
        self.active_key_index: int = 0
        # Default model (can be switched in Settings)
        self.model_name: str = "gemini-2.5-flash"
        # Whether to automatically refine the prompt before sending
        self.auto_refine: bool = False

        # Ensure logs show up at startup
        try:
            self._log_debug("MagicInput initialized; logging to debug.log and magicinput.log")
        except Exception:
            pass

        # Load existing config (API keys, model, UI)
        self._load_config()

        # Env var fallback for API key (append as a last-resort key)
        if not self.api_keys:
            env_key = os.environ.get("GEMINI_API_KEY")
            if env_key:
                self.api_keys = [env_key]
                self.active_key_index = 0
        # Keep legacy single api_key field in sync for downstream checks
        self.api_key = (self.api_keys[self.active_key_index]
                        if self.api_keys and 0 <= self.active_key_index < len(self.api_keys)
                        else None)

        # Configure Gemini client
        self._configure_gemini_client()
        self.file_paths: list[str] = []
        self.file_meta: dict[str, tuple[int,int,int]] = {}
        self.terminal_context_buffer: str = ""

        # Autocomplete state (for '@' mentions)
        self._ac_popup: tk.Toplevel | None = None
        self._ac_listbox: tk.Listbox | None = None
        self._ac_entries: list[str] = []
        self._ac_start_index: str | None = None  # Tk index string for '@' position

        # Create tray icon (Windows only, if pystray available)
        if platform.system() == 'Windows':
            self._create_tray_icon()

        # Ensure frameless window still shows in task-bar (Windows only)
        if platform.system() == 'Windows':
            self.root.after(100, self._ensure_taskbar_icon)

        # Archive the last prompt from the previous session if it exists
        try:
            if os.path.isfile(self.prompt_log_path):
                with open(self.prompt_log_path, "r", encoding="utf-8", errors="ignore") as f:
                    prev = f.read().strip()
                if prev and prev != self.waiting_placeholder:
                    sep = "\n" + ("-" * 50) + "\n"
                    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    with open(self.archive_path, "a", encoding="utf-8") as arch:
                        arch.write(f"[{timestamp}] (from previous session)\n{prev}{sep}")
        except Exception:
            pass # Ignore errors during this pre-flight check

        # Initialize prompt file with waiting placeholder and start countdown
        try:
            self._init_waiting_prompt(seconds=30)
        except Exception:
            pass

    # ------------------------------------------------------------------ UI BUILDERS
    def _configure_window(self) -> None:
        # App metadata
        self.app_name = "MagicInput"

        self.root.title(self.app_name)
        self.root.resizable(False, False)
        # Custom frameless window (no native decorations)
        self.root.overrideredirect(True)
        # Do NOT keep always on top so it can sit behind other windows
        self.root.attributes('-topmost', False)
        
        width, height = 780, 700  # Larger window to reduce wrapping and improve layout
        x = (self.root.winfo_screenwidth() - width) // 2
        y = (self.root.winfo_screenheight() - height) // 3
        self.root.geometry(f"{width}x{height}+{x}+{y}")
        
        # Apply theme background
        self.root.configure(bg=self.current_theme["bg_primary"])
        
        # Configure fonts and styles
        self.title_font = ('Segoe UI', 12, 'bold')
        self.text_font = ('Consolas', 10)
        self.button_font = ('Segoe UI', 10)

        style = ttk.Style()
        try:
            style.theme_use("vista")
        except tk.TclError:
            style.theme_use("clam")
        # Configure theme-aware TTK styles
        style.configure("TButton", padding=5, 
                       background=self.current_theme["bg_secondary"])
        style.configure("TLabel", background=self.current_theme["bg_primary"], 
                       foreground=self.current_theme["text_primary"], 
                       font=('Segoe UI', 10))
        style.configure("TFrame", background=self.current_theme["bg_primary"])

    def _create_widgets(self) -> None:
        # -------------------- Custom title bar -------------------- #
        self.title_bar = tk.Frame(self.root, bg=self.current_theme["bg_secondary"], 
                                 relief="flat", height=30)
        # Add emoji as app icon in title bar
        self.icon_lbl = tk.Label(self.title_bar, text=self.app_icon_emoji,
                                 font=('Segoe UI Emoji', 14),
                                 bg=self.current_theme['bg_secondary'],
                                 fg=self.current_theme['text_primary'])
        self.icon_lbl.pack(side=tk.LEFT, padx=(5, 0))
        self.title_lbl = tk.Label(self.title_bar, text=self.app_name, font=self.title_font,
                                 bg=self.current_theme["bg_secondary"], 
                                 fg=self.current_theme["text_primary"])

        # Theme toggle button (sun/moon icon)
        theme_icon = "☀" if self.is_dark_theme else "🌙"
        self.theme_btn = tk.Button(self.title_bar, text=theme_icon, 
                                  font=('Segoe UI', 10, 'bold'),
                                  bg=self.current_theme["bg_secondary"], 
                                  fg=self.current_theme["text_primary"], 
                                  relief="flat",
                                  command=self._toggle_theme)

        # Info (i) button to show developer details
        self.info_btn = tk.Button(self.title_bar, text="i", 
                                 font=('Segoe UI', 10, 'bold'),
                                 bg=self.current_theme["bg_secondary"], 
                                 fg=self.current_theme["text_primary"], 
                                 relief="flat",
                                 command=self._show_info)

        # Settings (gear) button
        self.settings_btn = tk.Button(self.title_bar, text="⚙", 
                                 font=('Segoe UI', 10, 'bold'),
                                 bg=self.current_theme["bg_secondary"], 
                                 fg=self.current_theme["text_primary"], 
                                 relief="flat",
                                 command=self._open_settings)

        # Minimize button (–)
        self.minimize_btn = tk.Button(self.title_bar, text="–", 
                                     font=('Segoe UI', 10, 'bold'),
                                     bg=self.current_theme["bg_secondary"], 
                                     fg=self.current_theme["text_primary"], 
                                     relief="flat",
                                     command=self._minimize)

        # Close button (×)
        self.close_btn = tk.Button(self.title_bar, text="×", 
                                  font=('Segoe UI', 10, 'bold'),
                                  bg=self.current_theme["bg_secondary"], 
                                  fg=self.current_theme["text_primary"], 
                                  relief="flat",
                                  command=self.root.destroy)

        # Attachment summary (always visible)
        self.attach_summary_var = tk.StringVar(value="")
        self.attach_summary_label = tk.Label(
            self.root,
            textvariable=self.attach_summary_var,
            font=self.text_font,
            bg=self.current_theme["bg_tertiary"],
            fg=self.current_theme["text_primary"],
            anchor="w",
            justify="left"
        )

        # Status line (for countdown / messages)
        self.status_var = tk.StringVar(value="")
        self.status_label = tk.Label(
            self.root,
            textvariable=self.status_var,
            font=('Segoe UI', 9),
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_secondary"],
            anchor="w",
            justify="left"
        )

        # Image preview canvas with better styling
        self.canvas = tk.Canvas(self.root, height=self.CANVAS_HEIGHT, 
                              bg=self.current_theme["bg_tertiary"], 
                              highlightthickness=1, 
                              highlightbackground=self.current_theme["border"])
        # Redraw placeholder when canvas is resized (avoids cropping)
        self.canvas.bind("<Configure>", lambda e: self._draw_placeholder())
        # Initial placeholder draw
        self._draw_placeholder()

        # Image section label
        self.img_label = tk.Label(self.root, text="Image Attachment", 
                                font=self.button_font,
                                bg=self.current_theme["bg_primary"], 
                                fg=self.current_theme["text_primary"], 
                                anchor="w")

        # Toolbar for image actions - more colorful buttons
        self.img_bar = tk.Frame(self.root, bg=self.current_theme["bg_primary"])
        self.add_btn = tk.Button(self.img_bar, text="Add Image", 
                               bg=self.current_theme["accent_blue"], 
                               fg=self.current_theme["text_primary"], 
                               font=self.button_font, relief="flat", 
                               command=self._add_image)
        self.remove_btn = tk.Button(self.img_bar, text="Remove", 
                                  bg=self.current_theme["accent_red"], 
                                  fg=self.current_theme["text_primary"], 
                                  font=self.button_font, relief="flat", 
                                  command=self._remove_image)
        self.prev_btn = tk.Button(self.img_bar, text="◀", width=3, 
                                bg=self.current_theme["bg_secondary"], 
                                fg=self.current_theme["text_primary"], 
                                font=self.button_font, relief="flat", 
                                command=self._prev_image)
        self.next_btn = tk.Button(self.img_bar, text="▶", width=3, 
                                bg=self.current_theme["bg_secondary"], 
                                fg=self.current_theme["text_primary"], 
                                font=self.button_font, relief="flat", 
                                command=self._next_image)
        self.counter_var = tk.StringVar(value="0/0")
        self.counter_lbl = tk.Label(self.img_bar, textvariable=self.counter_var,
                                  font=self.button_font, 
                                  bg=self.current_theme["bg_primary"], 
                                  fg=self.current_theme["text_primary"])
        self.file_btn = tk.Button(self.img_bar, text="Add File", 
                           bg=self.current_theme["accent_purple"], 
                           fg=self.current_theme["text_primary"], 
                           font=self.button_font, relief="flat", 
                           command=self._add_file)

        # Text section label
        self.text_label = tk.Label(self.root, text="Prompt", 
                                 font=self.button_font,
                                 bg=self.current_theme["bg_primary"], 
                                 fg=self.current_theme["text_primary"], 
                                 anchor="w")
        
        # Text / code input with scrollbar, larger height, and editor features
        self.text_input = scrolledtext.ScrolledText(
            self.root, wrap=tk.WORD, height=12, font=self.text_font,
            bg=self.current_theme["bg_tertiary"], 
            fg=self.current_theme["text_primary"],
            insertbackground=self.current_theme["accent_blue"]
        )
        self.text_input.configure(undo=True, maxundo=1000, autoseparators=True)
        self.text_input.bind("<KeyRelease>", self._on_key_release)

        # --- Basic text editor shortcuts ---
        def _undo(e):
            try:
                self.text_input.edit_undo()
            except Exception:
                pass
            return "break"

        def _redo(e):
            try:
                self.text_input.edit_redo()
            except Exception:
                pass
            return "break"

        def _cut(e):
            self.text_input.event_generate('<<Cut>>')
            return "break"

        def _copy(e):
            self.text_input.event_generate('<<Copy>>')
            return "break"

        def _paste(e):
            self.text_input.event_generate('<<Paste>>')
            return "break"

        def _select_all(e):
            self.text_input.tag_add('sel', '1.0', 'end-1c')
            return "break"

        def _move_sel_up(e):
            ti = self.text_input
            try:
                start = ti.index('sel.first'); end = ti.index('sel.last')
            except tk.TclError:
                start = ti.index('insert linestart'); end = ti.index('insert lineend')
            start_ls = ti.index(f"{start} linestart")
            if ti.compare(start_ls, '==', '1.0'):
                return "break"
            end_le = ti.index(f"{end} lineend +1c")
            prev_ls = ti.index(f"{start_ls} -1 line linestart")
            prev_le = ti.index(f"{start_ls} -1 line lineend +1c")
            prev_text = ti.get(prev_ls, prev_le)
            sel_text = ti.get(start_ls, end_le)
            ti.delete(prev_ls, end_le)
            ti.insert(prev_ls, sel_text + prev_text)
            ti.tag_remove('sel', '1.0', 'end')
            ti.tag_add('sel', prev_ls, ti.index(f"{prev_ls} + {len(sel_text)}c"))
            ti.see(prev_ls)
            return "break"

        def _move_sel_down(e):
            ti = self.text_input
            try:
                start = ti.index('sel.first'); end = ti.index('sel.last')
            except tk.TclError:
                start = ti.index('insert linestart'); end = ti.index('insert lineend')
            start_ls = ti.index(f"{start} linestart")
            end_le = ti.index(f"{end} lineend +1c")
            next_ls = ti.index(f"{end_le} linestart")
            if ti.compare(next_ls, '>=', 'end-1c'):
                return "break"
            next_le = ti.index(f"{next_ls} lineend +1c")
            sel_text = ti.get(start_ls, end_le)
            next_text = ti.get(next_ls, next_le)
            ti.delete(start_ls, next_le)
            ti.insert(start_ls, next_text + sel_text)
            new_start = ti.index(f"{start_ls} + {len(next_text)}c")
            ti.tag_remove('sel', '1.0', 'end')
            ti.tag_add('sel', new_start, ti.index(f"{new_start} + {len(sel_text)}c"))
            ti.see(new_start)
            return "break"

        # Bind editor shortcuts
        self.text_input.bind('<Control-z>', _undo)
        self.text_input.bind('<Control-Z>', _undo)
        self.text_input.bind('<Control-y>', _redo)
        self.text_input.bind('<Control-Y>', _redo)
        self.text_input.bind('<Control-Shift-z>', _redo)
        self.text_input.bind('<Control-Shift-Z>', _redo)
        self.text_input.bind('<Control-x>', _cut)
        self.text_input.bind('<Control-c>', _copy)
        self.text_input.bind('<Control-v>', _paste)
        self.text_input.bind('<Control-a>', _select_all)
        self.text_input.bind('<Alt-Up>', _move_sel_up)
        self.text_input.bind('<Alt-Down>', _move_sel_down)

        # Bottom buttons container (auto-size to fit added controls)
        self.btn_frame = tk.Frame(self.root, 
                                 bg=self.current_theme["bg_primary"])
        
        # Colored action buttons with hover effect
        self.clear_btn = tk.Button(self.btn_frame, text="Clear", 
                                 font=self.button_font,
                                 bg=self.current_theme["bg_secondary"], 
                                 fg=self.current_theme["text_primary"], 
                                 relief="flat", command=self._clear)
        self.send_btn = tk.Button(self.btn_frame, text="Send", 
                                font=self.button_font,
                                bg=self.current_theme["accent_green"], 
                                fg=self.current_theme["text_primary"], 
                                relief="flat", command=self._send)
        self.send_close_btn = tk.Button(self.btn_frame, text="Send & Close", 
                                      font=self.button_font,
                                      bg=self.current_theme["accent_blue"], 
                                      fg=self.current_theme["text_primary"], 
                                      relief="flat", 
                                      command=self._send_and_close)
        self.refine_btn = tk.Button(self.btn_frame, text="Refine", 
                               font=self.button_font,
                               bg=self.current_theme["accent_orange"], 
                               fg=self.current_theme["text_primary"], 
                               relief="flat", command=self._refine_prompt)
        # Dedicated Describe controls section (below image toolbar)
        self.describe_controls_frame = tk.Frame(self.root, bg=self.current_theme["bg_primary"])

        # Container for context toggles and mode selectors with a border
        self.options_frame = ttk.LabelFrame(self.describe_controls_frame, text="Options", style="TLabelframe")

        # Mode toggle: Plan | Describe | Combine
        self.mode_var = tk.StringVar(value="plan")
        self.mode_frame = tk.Frame(self.options_frame, bg=self.current_theme["bg_primary"])
        self.mode_conn_rb = tk.Radiobutton(
            self.mode_frame,
            text="Plan",
            value="plan",
            variable=self.mode_var,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            selectcolor=self.current_theme["bg_secondary"],
            activebackground=self.current_theme["bg_primary"],
            activeforeground=self.current_theme["text_primary"],
            command=self._on_prefs_changed
        )
        self.mode_desc_rb = tk.Radiobutton(
            self.mode_frame,
            text="Describe",
            value="describe",
            variable=self.mode_var,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            selectcolor=self.current_theme["bg_secondary"],
            activebackground=self.current_theme["bg_primary"],
            activeforeground=self.current_theme["text_primary"],
            command=self._on_prefs_changed
        )
        self.mode_comb_rb = tk.Radiobutton(
            self.mode_frame,
            text="Combine",
            value="combine",
            variable=self.mode_var,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            selectcolor=self.current_theme["bg_secondary"],
            activebackground=self.current_theme["bg_primary"],
            activeforeground=self.current_theme["text_primary"],
            command=self._on_prefs_changed
        )

        self.visionize_btn = tk.Button(self.btn_frame, text="Visionize", 
                               font=self.button_font,
                               bg=self.current_theme["accent_purple"], 
                               fg=self.current_theme["text_primary"], 
                               relief="flat", command=self._describe_image)
        
        self.visionize_send_btn = tk.Button(self.btn_frame, text="Visionize & Send", 
                               font=self.button_font,
                               bg=self.current_theme["accent_purple"], 
                               fg=self.current_theme["text_primary"], 
                               relief="flat", command=self._visionize_and_send)

        # Include context checkbox for Describe Image
        # Second-row container for context toggles (inside options frame)
        self.ctx_frame = tk.Frame(self.options_frame, bg=self.current_theme["bg_primary"])

        self.include_context_var = tk.BooleanVar(value=True)
        self.include_context_chk = tk.Checkbutton(
            self.ctx_frame,
            text="Include context",
            variable=self.include_context_var,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            selectcolor=self.current_theme["bg_primary"],
            activebackground=self.current_theme["bg_primary"],
            activeforeground=self.current_theme["text_primary"],
            command=lambda: (self._on_toggle_include_context(), self._on_prefs_changed())
        )

        # Per-context toggles
        self.include_project_var = tk.BooleanVar(value=True)
        self.include_project_chk = tk.Checkbutton(
            self.ctx_frame,
            text="Project brief",
            variable=self.include_project_var,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            selectcolor=self.current_theme["bg_primary"],
            activebackground=self.current_theme["bg_primary"],
            activeforeground=self.current_theme["text_primary"],
            command=self._on_prefs_changed
        )

        self.include_archive_var = tk.BooleanVar(value=True)
        self.include_archive_chk = tk.Checkbutton(
            self.ctx_frame,
            text="Prompts archive",
            variable=self.include_archive_var,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            selectcolor=self.current_theme["bg_primary"],
            activebackground=self.current_theme["bg_primary"],
            activeforeground=self.current_theme["text_primary"],
            command=self._on_prefs_changed
        )

        self.include_terminal_var = tk.BooleanVar(value=True)
        self.include_terminal_chk = tk.Checkbutton(
            self.ctx_frame,
            text="Terminal",
            variable=self.include_terminal_var,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            selectcolor=self.current_theme["bg_primary"],
            activebackground=self.current_theme["bg_primary"],
            activeforeground=self.current_theme["text_primary"],
            command=self._on_prefs_changed
        )

        # Button to preload/paste terminal context
        self.terminal_ctx_btn = tk.Button(
            self.btn_frame,
            text="Terminal…",
            font=self.button_font,
            bg=self.current_theme["bg_secondary"],
            fg=self.current_theme["text_primary"],
            relief="flat",
            command=self._open_terminal_context_dialog
        )
        
        # Add hover effects
        for btn in (self.add_btn, self.file_btn, self.remove_btn, self.prev_btn, self.next_btn,
                   self.clear_btn, self.refine_btn, self.send_btn, self.send_close_btn, 
                   self.visionize_btn, self.visionize_send_btn,
                   self.info_btn, self.settings_btn, self.theme_btn, self.minimize_btn, self.close_btn):
            btn.bind("<Enter>", lambda e, b=btn: self._on_hover(b, True))
            btn.bind("<Leave>", lambda e, b=btn: self._on_hover(b, False))

    def _layout_widgets(self) -> None:
        # Title bar layout
        self.title_bar.pack(fill=tk.X)
        self.title_lbl.pack(side=tk.LEFT, padx=10)

        # Attachment summary line
        self.attach_summary_label.pack(fill=tk.X, padx=10, pady=(0, 4))
        self.status_label.pack(fill=tk.X, padx=10, pady=(0, 6))
        self.close_btn.pack(side=tk.RIGHT, padx=5)
        self.minimize_btn.pack(side=tk.RIGHT)
        self.info_btn.pack(side=tk.RIGHT)
        self.settings_btn.pack(side=tk.RIGHT)
        self.theme_btn.pack(side=tk.RIGHT, padx=5)
        
        # Allow dragging window from custom title bar
        self.title_bar.bind("<ButtonPress-1>", self._start_move)
        self.title_bar.bind("<B1-Motion>", self._on_move)

        # Image section
        self.img_label.pack(fill=tk.X, padx=10, pady=(10, 5), anchor="w")
        self.canvas.pack(fill=tk.X, padx=10, pady=(0, 5))

        # Image toolbar
        self.img_bar.pack(fill=tk.X, padx=10, pady=(0, 10))
        # Reorganized spacing for clearer alignment: Add Image, Add File, Remove
        self.add_btn.pack(side=tk.LEFT, ipady=2, ipadx=6)
        self.file_btn.pack(side=tk.LEFT, padx=(6, 0), ipady=2, ipadx=6)
        self.remove_btn.pack(side=tk.LEFT, padx=(6, 0), ipady=2, ipadx=6)
        self.prev_btn.pack(side=tk.RIGHT)
        self.next_btn.pack(side=tk.RIGHT, padx=(0, 5))
        self.counter_lbl.pack(side=tk.RIGHT, padx=5)

        # Describe controls section (between image toolbar and text area)
        self.describe_controls_frame.pack(fill=tk.X, padx=10, pady=(0, 8))
        # Options frame containing toggles and modes
        self.options_frame.pack(fill=tk.X, padx=0, pady=(4, 0))
        self.ctx_frame.pack(side=tk.LEFT, fill=tk.X, padx=5, pady=2)
        self.mode_frame.pack(side=tk.LEFT, padx=5, pady=2)
        self.mode_conn_rb.pack(side=tk.LEFT)
        self.mode_desc_rb.pack(side=tk.LEFT, padx=(6,0))
        self.mode_comb_rb.pack(side=tk.LEFT, padx=(6,0))
        self.include_context_chk.pack(side=tk.LEFT, padx=(0,8))
        self.include_project_chk.pack(side=tk.LEFT, padx=(0,8))
        self.include_archive_chk.pack(side=tk.LEFT, padx=(0,8))
        self.include_terminal_chk.pack(side=tk.LEFT, padx=(0,8))

        # Text section
        self.text_label.pack(fill=tk.X, padx=10, pady=(0, 5), anchor="w")
        # Extra spacing below input for visual comfort before buttons
        self.text_input.pack(fill=tk.X, expand=False, padx=10, pady=(0, 16))

        # Bottom buttons anchored to bottom
        self.btn_frame.pack(side=tk.BOTTOM, fill=tk.X, padx=10, pady=(0, 10))
        
        # Top row (actions)
        self.terminal_ctx_btn.pack(side=tk.LEFT, pady=6, ipady=3, ipadx=8)
        self.clear_btn.pack(side=tk.LEFT, padx=(5,0), pady=6, ipady=3, ipadx=8)
        self.refine_btn.pack(side=tk.LEFT, padx=(5,0), pady=6, ipady=3, ipadx=8)
        self.send_close_btn.pack(side=tk.RIGHT, pady=6, ipady=3, ipadx=8)
        self.send_btn.pack(side=tk.RIGHT, padx=(0, 5), pady=6, ipady=3, ipadx=8)
        self.visionize_btn.pack(side=tk.RIGHT, padx=(0, 5), pady=6, ipady=3, ipadx=8)
        self.visionize_send_btn.pack(side=tk.RIGHT, padx=(0, 5), pady=6, ipady=3, ipadx=8)

        # Sync state and update layout/status
        self._on_toggle_include_context()
        try:
            self.status_var.set("🧩 Describe controls ready")
            self.root.update_idletasks()
        except Exception:
            pass

        # ------------------------------------------------------------------ KEYBOARD SHORTCUTS
        # Ctrl+Enter -> Send
        self.root.bind_all('<Control-Return>', lambda e: self._send_and_close())
        # Ctrl+V -> Paste image from clipboard
        self.root.bind_all('<Control-v>', lambda e: self._paste_clipboard_image())

    def _enable_dnd(self) -> None:
        # Canvas accepts image files; text area accepts files whose contents are inserted.
        self.canvas.drop_target_register(DND_FILES)  # type: ignore
        self.canvas.dnd_bind("<<Drop>>", self._on_canvas_drop)  # type: ignore
        self.text_input.drop_target_register(DND_FILES)  # type: ignore
        self.text_input.dnd_bind("<<Drop>>", self._on_text_drop)  # type: ignore

    # ------------------------------------------------------------------ IMAGE HANDLING
    def _draw_placeholder(self) -> None:
        self.canvas.delete("all")
        w = self.canvas.winfo_width() or self.canvas.winfo_reqwidth()
        h = self.CANVAS_HEIGHT
        # Draw a nicer placeholder with icon-like appearance
        self.canvas.create_rectangle(w//2-40, h//2-30, w//2+40, h//2+30,
                                   outline=self.current_theme["border"], 
                                   fill=self.current_theme["bg_tertiary"])
        self.canvas.create_line(w//2-20, h//2, w//2+20, h//2, 
                              fill=self.current_theme["text_secondary"])
        self.canvas.create_line(w//2, h//2-20, w//2, h//2+20, 
                              fill=self.current_theme["text_secondary"])
        self.canvas.create_text(w//2, h//2+50, text="Drag & drop image or click 'Add Image'", 
                              fill=self.current_theme["text_secondary"], 
                              font=('Segoe UI', 9))
        self.current_photo = None

    def _update_counter(self) -> None:
        total = len(self.images)
        current = self.current_index + 1 if total else 0
        self.counter_var.set(f"{current}/{total}")

    def _refresh_summary(self) -> None:
        """Update the one-line attachment summary shown under the title bar."""
        parts: list[str] = []
        for p in self.file_paths:
            meta = self.file_meta.get(p)
            if meta:
                s_line, e_line, total = meta
                label = f"📄 {os.path.basename(p)} ({s_line}-{e_line}/{total})"
            else:
                label = f"📄 {os.path.basename(p)}"
            parts.append(label)

        # Show generic image labels without any file paths
        parts.extend(f"🖼 Image {i+1}" for i in range(len(self.images)))
        self.attach_summary_var.set("  |  ".join(parts))

    def _add_image(self) -> None:
        paths = filedialog.askopenfilenames(title="Select image(s)", filetypes=[("Images", "*.png *.jpg *.jpeg *.gif *.bmp")])
        if paths:
            threading.Thread(target=self._process_images_thread, args=(paths,)).start()

    def _process_images_thread(self, paths: tuple) -> None:
        for p in paths:
            try:
                with Image.open(p) as img:
                    try:
                        img = img.convert("RGBA")
                    except Exception:
                        pass
                    buf = BytesIO()
                    img.save(buf, format="PNG")
                    buf.seek(0)
                    data = {"bytes": buf.getvalue(), "name": os.path.basename(p)}
                # Add to UI/in-memory on main thread
                self.root.after(0, lambda d=data: self._add_image_to_ui(d))
            except Exception as e:
                self.root.after(0, lambda err=e: messagebox.showerror("Error", f"Failed to add image: {err}"))

    def _add_image_to_ui(self, img_data: dict[str, Any]) -> None:
        """Append an in-memory image and update the UI without inserting any path mentions."""
        self.images.append(img_data)
        self.current_index = len(self.images) - 1
        self._show_current_image()
        self._update_counter()
        self._refresh_summary()

    def _store_image(self, src_path: str) -> None:
        """Load an image from disk and store it in-memory (no path persistence)."""
        try:
            with Image.open(src_path) as img:
                try:
                    img = img.convert("RGBA")
                except Exception:
                    pass
                buf = BytesIO()
                img.save(buf, format="PNG")
                buf.seek(0)
                self.images.append({"bytes": buf.getvalue(), "name": os.path.basename(src_path)})
            self._refresh_summary()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to add image: {e}")

    def _show_current_image(self) -> None:
        if not self.images:
            self._draw_placeholder()
            return
        img_data = self.images[self.current_index]
        threading.Thread(target=self._load_image_for_display, args=(img_data,)).start()

    def _load_image_for_display(self, img_data: dict[str, Any]) -> None:
        try:
            img = Image.open(BytesIO(img_data.get("bytes", b"")))
            canvas_w = self.canvas.winfo_width() or self.canvas.winfo_reqwidth()
            canvas_h = self.CANVAS_HEIGHT
            img.thumbnail((canvas_w - 4, canvas_h - 4))
            photo = ImageTk.PhotoImage(img)
            self.root.after(0, lambda: self._update_image_canvas(photo))
        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Error", f"Cannot display image: {e}"))
            self.root.after(0, lambda: (self.images.pop(self.current_index) if self.images else None))
            self.root.after(0, self._update_counter)
            self.root.after(0, self._draw_placeholder)

    def _update_image_canvas(self, photo: ImageTk.PhotoImage) -> None:
        self.canvas.delete("all")
        self.current_photo = photo
        canvas_w = self.canvas.winfo_width() or self.canvas.winfo_reqwidth()
        canvas_h = self.CANVAS_HEIGHT
        self.canvas.create_image(canvas_w // 2, canvas_h // 2, image=self.current_photo)

    def _log_debug(self, msg: str, exc: Exception | None = None) -> None:
        """Append debug messages to a log file in `MagicInput/` with timestamp."""
        try:
            ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            line = f"[{ts}] {msg}\n"
            if exc is not None:
                import traceback
                line += traceback.format_exc() + "\n"
            # Write to both standard and legacy log files
            try:
                with open(self.log_path, "a", encoding="utf-8") as f:
                    f.write(line)
            except Exception:
                pass
            try:
                with open(self.legacy_log_path, "a", encoding="utf-8") as f2:
                    f2.write(line)
            except Exception:
                pass
        except Exception:
            pass

    def _remove_image(self) -> None:
        if not self.images:
            return
        del self.images[self.current_index]
        self.current_index = max(0, self.current_index - 1)
        self._show_current_image()
        self._update_counter()
        self._refresh_summary()

    def _next_image(self) -> None:
        if not self.images:
            return
        self.current_index = (self.current_index + 1) % len(self.images)
        self._show_current_image()
        self._update_counter()

    def _prev_image(self) -> None:
        if not self.images:
            return
        self.current_index = (self.current_index - 1) % len(self.images)
        self._show_current_image()
        self._update_counter()

    def _add_file(self) -> None:
        paths = filedialog.askopenfilenames(title="Select file(s)", initialdir=self.app_dir)
        if paths:
            threading.Thread(target=self._process_files_thread, args=(paths,)).start()

    def _process_files_thread(self, paths: tuple) -> None:
        for p in paths:
            try:
                _, ext = os.path.splitext(p)
                existing_nums = []
                for fname in os.listdir(self.attachments_dir):
                    if fname.startswith("MagicInput File "):
                        try:
                            num_part = fname.split("MagicInput File ")[1].split(".")[0]
                            existing_nums.append(int(num_part))
                        except (IndexError, ValueError):
                            pass
                next_num = max(existing_nums, default=0) + 1
                dest = os.path.join(self.attachments_dir, f"MagicInput File {next_num}{ext}")
                shutil.copy(p, dest)
                self.root.after(0, lambda d=dest: self._add_file_to_ui(d))
            except Exception as e:
                self.root.after(0, lambda err=e: messagebox.showerror("Error", f"Failed to add file: {err}"))

    def _add_file_to_ui(self, dest_path: str) -> None:
        self.file_paths.append(dest_path)
        self._insert_file_mention(dest_path)
        self._refresh_summary()

    # ------------------------------------------------------------------ DRAG-AND-DROP EVENTS
    def _on_canvas_drop(self, event):  # noqa: N802 (tkinter callback name)
        image_paths_to_process = []
        file_paths_to_process = []
        for filepath in self.root.tk.splitlist(event.data):
            lower = filepath.lower()
            if lower.endswith((".png", ".jpg", ".jpeg", ".gif", ".bmp")):
                image_paths_to_process.append(filepath)
            else:
                file_paths_to_process.append(filepath)
        
        if image_paths_to_process:
            threading.Thread(target=self._process_images_thread, args=(image_paths_to_process,)).start()
        
        for p in file_paths_to_process:
            threading.Thread(target=self._process_files_thread, args=([p],)).start()

    def _on_text_drop(self, event):  # noqa: N802
        filepath = self.root.tk.splitlist(event.data)[0]
        if os.path.isfile(filepath):
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    self.text_input.insert(tk.END, f.read())
            except Exception as e:
                messagebox.showerror("Error", f"Cannot read file: {e}")

    # ------------------------------------------------------------------ BUTTON COMMANDS
    def _clear(self) -> None:
        if messagebox.askyesno("Confirm", "Clear all inputs?"):
            self.images.clear()
            self.current_index = 0
            self.text_input.delete("1.0", tk.END)
            self._draw_placeholder()
            self._update_counter()
            self._refresh_summary()

    def _collect_data(self) -> str:
        """Gather user input and attachment paths as formatted text."""
        text = self.text_input.get("1.0", tk.END).strip()

        # ----------------------------------------------------
        # Append footer directive based on attachment types
        # ----------------------------------------------------
        footer_parts: list[str] = []

        # Determine if any images are present
        if self.images:
            footer_parts.append("screenshot/image")

        # Classify files between code and other attachments
        code_exts = {
            ".py", ".js", ".ts", ".tsx", ".jsx", ".c", ".cpp", ".h", ".hpp", ".cs", ".java",
            ".rb", ".go", ".rs", ".swift", ".kt", ".kts", ".php", ".pl", ".sh", ".bat", ".cmd",
            ".sql", ".xml", ".json", ".yaml", ".yml", ".css", ".scss", ".html", ".htm", ".md",
            ".txt",
        }

        code_found = False
        other_found = False
        for p in self.file_paths:
            _, ext = os.path.splitext(p)
            if ext.lower() in code_exts:
                code_found = True
            else:
                other_found = True

        if code_found:
            footer_parts.append("Code/file")
        if other_found and not code_found:
            # Only non-code files present ➔ treat as generic attachment
            footer_parts.append("attachement")
        elif other_found and code_found:
            # Both code and other attachment types present ➔ mention both
            footer_parts.append("attachement")

        # Build footer sentence
        footer_line = ""
        if footer_parts:
            if len(footer_parts) == 1:
                parts_str = footer_parts[0]
            else:
                parts_str = " and ".join(footer_parts)
            footer_line = f"read the {parts_str} (following the directory link) mentioned above."

        if footer_line:
            text = f"{text}\n{footer_line}" if text else footer_line

        lines: list[str] = []
        lines.append("Prompt:")
        lines.append(text)

        if self.file_paths:
            lines.append("")  # blank line before attachment section
            lines.append("Attachments:")
            # only files (exclude images — they are already mentioned inline)
            for p in self.file_paths:
                meta = self.file_meta.get(p)
                if meta:
                    s_line, e_line, total = meta
                    extra = f" ({s_line}-{e_line}/{total})"
                else:
                    extra = ""
                lines.append("@" + os.path.abspath(p) + extra)

        return "\n".join(lines)

    def _send(self) -> None:
        # Auto-refine prompt before processing if enabled
        if getattr(self, "auto_refine", False):
            self._refine_prompt()

        # Attempt to auto-detect file matches for pasted snippet
        threading.Thread(target=self._detect_snippet_files_thread).start()
        self._extract_mentioned_files()
        collected = self._collect_data()
        # Cancel countdown if running
        try:
            if hasattr(self, "_countdown_after_id") and self._countdown_after_id is not None:
                self.root.after_cancel(self._countdown_after_id)
                self._countdown_after_id = None
        except Exception:
            pass
        # Print to terminal
        # Ensure stdout uses UTF-8 if the attribute exists (Python 3.7+)
        if hasattr(sys.stdout, "reconfigure"):
            sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        print(collected)
        sys.stdout.flush()
        # Persist prompt: keep last only; archive previous
        try:
            self._persist_prompt(collected)
            self.status_var.set("✅ Prompt saved")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to write prompt file: {e}")

        # (Deprecated) old append-based persistence replaced by _persist_prompt()

    def _send_and_close(self) -> None:
        self._send()
        self.root.after(100, self.root.destroy)

    def _visionize_and_send(self) -> None:
        """Visionize the image, then immediately send and close"""
        if not self.api_key:
            self.root.after(0, lambda: messagebox.showwarning("Gemini API","Gemini AI not configured. Please set the API key via Settings (⚙) or GEMINI_API_KEY env var."))
            return

        # Visionize & Send now works with or without images - it can analyze files/codes/prompt
        if not self.images and not self.file_paths and not self.text_input.get("1.0", tk.END).strip():
            self.root.after(0, lambda: messagebox.showwarning("Visionize & Send","Please add an image, attach files, or enter a prompt to analyze."))
            return

        # Create a modified callback that will send and close after describe completes
        def visionize_complete_callback():
            # Small delay to ensure the describe result is fully processed
            self.root.after(500, self._send_and_close)

        # Start visionize in background thread, then trigger send & close when done
        threading.Thread(target=self._visionize_and_send_thread, args=(visionize_complete_callback,)).start()

    def _visionize_and_send_thread(self, callback) -> None:
        """Execute visionize in background thread and call callback when done"""
        try:
            # Get the current settings similar to _describe_image
            try:
                include_ctx = self.include_context_var.get()
            except Exception:
                include_ctx = True

            enhanced_context = {}
            if include_ctx:
                if getattr(self, 'include_project_var', None) and self.include_project_var.get():
                    enhanced_context['project'] = True
                if getattr(self, 'include_archive_var', None) and self.include_archive_var.get():
                    enhanced_context['archive'] = True
                if getattr(self, 'include_terminal_var', None) and self.include_terminal_var.get():
                    enhanced_context['terminal'] = True

            try:
                user_prompt = self.text_input.get("1.0", tk.END).strip()
            except Exception:
                user_prompt = ""

            try:
                mode = self.mode_var.get()
            except Exception:
                mode = "plan"

            # Execute the describe image functionality
            self._describe_image_thread(mode, user_prompt, include_ctx, enhanced_context)
            
            # Call the completion callback on main thread
            self.root.after(0, callback)

        except Exception as e:
            self._log_debug(f"Error in visionize_and_send_thread: {e}", e)
            # Still call callback even if there was an error
            self.root.after(0, callback)

    # ------------------------------------------------------------------ CLEANUP
    def cleanup(self) -> None:
        shutil.rmtree(self.temp_dir, ignore_errors=True)
        # Stop tray icon if running
        if hasattr(self, "tray_icon") and self.tray_icon is not None:
            try:
                self.tray_icon.stop()
            except Exception:
                pass

    def _on_hover(self, button, entering):
        """Handle hover effect for buttons"""
        current_bg = button["bg"]
        # Compare with theme colors for proper hover effect
        if entering:  # Mouse entering - adjust color
            if current_bg == self.current_theme["accent_primary"]:
                button["bg"] = self.current_theme["hover_primary"]
            elif current_bg == self.current_theme["accent_secondary"]:
                button["bg"] = self.current_theme["hover_secondary"]
            elif current_bg == self.current_theme["button_danger"]:
                button["bg"] = self.current_theme["hover_danger"]
            elif current_bg == self.current_theme["button_secondary"]:
                button["bg"] = self.current_theme["hover_secondary"]
            elif current_bg == self.current_theme["bg_header"]:
                button["bg"] = self.current_theme["hover_secondary"]
        else:  # Mouse leaving - restore
            if current_bg == self.current_theme["hover_primary"]:
                button["bg"] = self.current_theme["accent_primary"]
            elif current_bg == self.current_theme["hover_secondary"] and button == self.send_btn:
                button["bg"] = self.current_theme["accent_secondary"]
            elif current_bg == self.current_theme["hover_danger"]:
                button["bg"] = self.current_theme["button_danger"]
            elif current_bg == self.current_theme["hover_secondary"] and button in [self.prev_btn, self.next_btn, self.clear_btn]:
                button["bg"] = self.current_theme["button_secondary"]
            elif current_bg == self.current_theme["hover_secondary"] and button in [self.info_btn, self.settings_btn, self.theme_btn, self.minimize_btn, self.close_btn]:
                button["bg"] = self.current_theme["bg_header"]

    # ------------------------------------------------------------------ INFO POPUP
    def _show_info(self) -> None:
        # Show custom themed info dialog instead of default messagebox
        info_text = (
            "Developer: Badiuzzaman Majnu\n"
            "Professional Graphics Designer, Developer, Freelancer.\n\n"
            "WhatsApp: +8801796072129\n"
            "Facebook: https://www.facebook.com/bmajnu786\n"
            "Email: badiuzzamanmajnu786@gmail.com"
        )
        popup = tk.Toplevel(self.root)
        popup.title(self.app_name)
        popup.configure(bg=self.current_theme["bg_primary"])
        popup.transient(self.root)
        popup.resizable(False, False)
        # Remove native window decorations
        popup.overrideredirect(True)
        # Content frame
        frame = tk.Frame(popup, bg=self.current_theme["bg_primary"])
        frame.pack(fill="both", expand=True, padx=20, pady=20)
        # Info label
        label = tk.Label(
            frame, text=info_text,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            font=self.text_font,
            justify="left",
            wraplength=360
        )
        label.pack(fill="both", expand=True)
        # OK button
        btn = tk.Button(
            frame, text="OK",
            bg=self.current_theme["accent_blue"],
            fg=self.current_theme["text_primary"],
            font=self.button_font,
            relief="flat",
            command=popup.destroy
        )
        btn.pack(pady=(10, 0))
        # Hover effect
        btn.bind("<Enter>", lambda e: btn.config(bg=self.current_theme["accent_purple"]))
        btn.bind("<Leave>", lambda e: btn.config(bg=self.current_theme["accent_blue"]))

        # Allow dragging the popup by holding anywhere inside
        _drag_data = {"x": 0, "y": 0}

        def _start_drag(evt):
            _drag_data["x"] = evt.x
            _drag_data["y"] = evt.y

        def _on_drag(evt):
            x = evt.x_root - _drag_data["x"]
            y = evt.y_root - _drag_data["y"]
            popup.geometry(f"+{x}+{y}")

        popup.bind("<ButtonPress-1>", _start_drag)
        popup.bind("<B1-Motion>", _on_drag)

        # Close on Esc key
        popup.bind("<Escape>", lambda e: popup.destroy())

        # Centre relative to the parent window (works even for frameless root)
        root_x = self.root.winfo_rootx()
        root_y = self.root.winfo_rooty()
        x = root_x + (self.root.winfo_width() - popup.winfo_width()) // 2
        y = root_y + (self.root.winfo_height() - popup.winfo_height()) // 2
        popup.geometry(f"+{x}+{y}")

        # Bring popup to front reliably
        popup.lift()
        popup.attributes('-topmost', True)
        popup.after(200, lambda: popup.attributes('-topmost', False))
        popup.focus_force()

    # ------------------------------------------------------------------ WINDOW DRAGGING
    def _start_move(self, event):  # noqa: N802
        self._x_offset = event.x
        self._y_offset = event.y

    def _on_move(self, event):  # noqa: N802
        x = event.x_root - getattr(self, '_x_offset', 0)
        y = event.y_root - getattr(self, '_y_offset', 0)
        self.root.geometry(f"+{x}+{y}")

    def _paste_clipboard_image(self) -> None:
        """Attempt to paste an image from the system clipboard (Ctrl+V)."""
        threading.Thread(target=self._paste_clipboard_image_thread).start()

    def _paste_clipboard_image_thread(self) -> None:
        try:
            data = ImageGrab.grabclipboard()
            if isinstance(data, Image.Image):
                # Store clipboard image directly in-memory
                try:
                    img = data.convert("RGBA")
                except Exception:
                    img = data
                buf = BytesIO()
                img.save(buf, format="PNG")
                buf.seek(0)
                image_data = {"bytes": buf.getvalue(), "name": "clipboard.png"}
                self.root.after(0, lambda d=image_data: self._add_image_to_ui(d))
            elif isinstance(data, list):
                # Clipboard may contain file paths
                for p in data:
                    if os.path.isfile(p):
                        self.root.after(0, lambda: self._store_image_and_update_ui(p))
            else:
                return  # Clipboard doesn't contain an image

        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Error", f"Cannot paste image from clipboard: {e}"))

    def _store_image_and_update_ui(self, path: str) -> None:
        self._store_image(path)
        if self.images:
            self.current_index = len(self.images) - 1
            self._show_current_image()
            self._update_counter()
            self._refresh_summary()

    # ------------------------------------------------------------------ WINDOW CONTROL METHODS
    def _minimize(self):
        """Minimize window while temporarily disabling overrideredirect."""
        # Turn off frameless to allow minimization
        self.root.overrideredirect(False)
        self.root.iconify()

    def _restore_override(self, event=None):  # noqa: D401
        """Re-apply overrideredirect after window is restored from iconify."""
        if self.root.state() == 'normal':
            self.root.overrideredirect(True)
            # Re-apply style to ensure taskbar icon persists
            if platform.system() == 'Windows':
                self._ensure_taskbar_icon()

    # ------------------------------------------------------------------ PLATFORM HELPERS

    def _ensure_taskbar_icon(self):
        """On Windows, adjust window styles so override-redirect window is shown in task-bar."""
        try:
            if platform.system() != 'Windows':
                return

            GWL_EXSTYLE = -20
            WS_EX_TOOLWINDOW = 0x00000080
            WS_EX_APPWINDOW = 0x00040000

            hwnd = self.root.winfo_id()
            user32 = ctypes.windll.user32
            style = user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
            # Remove TOOLWINDOW and add APPWINDOW
            style = style & ~WS_EX_TOOLWINDOW | WS_EX_APPWINDOW
            user32.SetWindowLongW(hwnd, GWL_EXSTYLE, style)

        except Exception:
            # Fail silently if ctypes operations not permitted
            pass

    # ------------------------------------------------------------------ TRAY ICON

    def _create_tray_icon(self):
        """Create a system-tray icon with Show and Exit actions using the magic emoji."""
        if pystray is None:
            return
        from PIL import ImageDraw, ImageFont

        # Create an RGBA image for the emoji icon
        size = 64
        bg = self.current_theme.get('accent_primary', '#BB86FC')
        fg = self.current_theme.get('fg_header', '#FFFFFF')
        img = Image.new('RGBA', (size, size), bg)
        draw = ImageDraw.Draw(img)

        # Load system emoji font on Windows
        font = None
        if os.name == 'nt':
            # Use raw string for default Windows directory to avoid escape-sequence warning
            font_path = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts', 'seguiemj.ttf')
            try:
                font = ImageFont.truetype(font_path, 48)
            except Exception:
                font = None
        if font is None:
            font = ImageFont.load_default()

        # Draw the emoji centered
        text = self.app_icon_emoji
        # Measure the size of the emoji text
        bbox = draw.textbbox((0, 0), text, font=font)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        draw.text(((size - w) / 2, (size - h) / 2), text, font=font, fill=fg)

        # Build tray menu
        menu = pystray.Menu(
            pystray.MenuItem('Show', lambda: self.root.after(0, self._show_window), default=True),
            pystray.MenuItem('Exit', lambda: self.root.after(0, self.root.destroy))
        )

        # Start the tray icon
        self.tray_icon = pystray.Icon('MagicInput', img, 'MagicInput', menu)
        threading.Thread(target=self.tray_icon.run, daemon=True).start()

    def _show_window(self):
        """Restore and focus the window from the tray."""
        self.root.deiconify()
        # Bring window to the front reliably
        self.root.attributes('-topmost', True)
        self.root.lift()
        self.root.focus_force()
        # Disable always-on-top again to preserve user stacking order
        self.root.after(200, lambda: self.root.attributes('-topmost', False))

    # ------------------------------------------------------------------ THEME TOGGLING

    def _toggle_theme(self):
        """Switch between dark and light themes."""
        self.is_dark_theme = not self.is_dark_theme
        self.current_theme = Theme.dark() if self.is_dark_theme else Theme.light()

        # --- Update all widget colors ---
        theme = self.current_theme
        
        # Root window
        self.root.configure(bg=theme["bg_primary"])

        # Title bar
        self.title_bar.configure(bg=theme["bg_secondary"])
        self.icon_lbl.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.title_lbl.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        
        # Title bar buttons
        theme_icon = "☀" if self.is_dark_theme else "🌙"
        self.theme_btn.configure(text=theme_icon, bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.info_btn.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.settings_btn.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.minimize_btn.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.close_btn.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])

        # Labels and status
        self.attach_summary_label.configure(bg=theme["bg_tertiary"], fg=theme["text_primary"])
        self.status_label.configure(bg=theme["bg_primary"], fg=theme["text_secondary"])
        self.img_label.configure(bg=theme["bg_primary"], fg=theme["text_primary"])
        self.text_label.configure(bg=theme["bg_primary"], fg=theme["text_primary"])

        # Image canvas and toolbar
        self.canvas.configure(bg=theme["bg_tertiary"], highlightbackground=theme["border"])
        self.img_bar.configure(bg=theme["bg_primary"])
        self.add_btn.configure(bg=theme["accent_blue"], fg=theme["text_primary"])
        self.file_btn.configure(bg=theme["accent_purple"], fg=theme["text_primary"])
        self.remove_btn.configure(bg=theme["accent_red"], fg=theme["text_primary"])
        self.prev_btn.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.next_btn.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.counter_lbl.configure(bg=theme["bg_primary"], fg=theme["text_primary"])

        # Prompt input
        self.text_input.configure(bg=theme["bg_tertiary"], fg=theme["text_primary"], insertbackground=theme["accent_blue"])

        # Describe controls and options frame
        self.describe_controls_frame.configure(bg=theme["bg_primary"])
        self.ctx_frame.configure(bg=theme["bg_primary"])
        self.mode_frame.configure(bg=theme["bg_primary"])

        # Checkboxes
        for chk in (self.include_context_chk, self.include_project_chk, self.include_archive_chk, self.include_terminal_chk):
            chk.configure(
                bg=theme["bg_primary"],
                fg=theme["text_primary"],
                selectcolor=theme["bg_primary"],
                activebackground=theme["bg_primary"],
                activeforeground=theme["text_primary"]
            )

        # Radio buttons
        for rb in (self.mode_conn_rb, self.mode_desc_rb, self.mode_comb_rb):
            rb.configure(
                bg=theme["bg_primary"],
                fg=theme["text_primary"],
                selectcolor=theme["bg_secondary"],
                activebackground=theme["bg_primary"],
                activeforeground=theme["text_primary"]
            )

        # Bottom buttons
        self.btn_frame.configure(bg=theme["bg_primary"])
        self.terminal_ctx_btn.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.visionize_btn.configure(bg=theme["accent_purple"], fg=theme["text_primary"])
        self.clear_btn.configure(bg=theme["bg_secondary"], fg=theme["text_primary"])
        self.refine_btn.configure(bg=theme["accent_orange"], fg=theme["text_primary"])
        self.send_btn.configure(bg=theme["accent_green"], fg=theme["text_primary"])
        self.send_close_btn.configure(bg=theme["accent_blue"], fg=theme["text_primary"])

        # Re-apply styles to all relevant ttk widgets
        style = ttk.Style()
        style.configure("TButton", padding=5, background=theme["bg_secondary"])
        style.configure("TLabel", background=theme["bg_primary"], foreground=theme["text_primary"])
        style.configure("TFrame", background=theme["bg_primary"])
        style.configure("TLabelframe", background=theme["bg_primary"])
        style.configure("TLabelframe.Label", background=theme["bg_primary"], foreground=theme["text_secondary"])

        # Redraw placeholder to update its color
        self._draw_placeholder()
        
        # Save the new theme preference
        self._on_prefs_changed()
        
        # Update the theme toggle button icon
        self.theme_btn.config(text="☀" if self.is_dark_theme else "🌙")
        
        # Update main window
        self.root.configure(bg=self.current_theme["bg_primary"])

        # Style for ttk widgets
        style = ttk.Style()
        style.configure("TLabelframe", background=self.current_theme["bg_primary"])
        style.configure("TLabelframe.Label", background=self.current_theme["bg_primary"], foreground=self.current_theme["text_secondary"])

        # Update title bar
        title_bar_widgets = [self.title_bar, self.title_lbl, self.theme_btn, 
                           self.info_btn, self.minimize_btn, self.close_btn]
        for widget in title_bar_widgets:
            widget.configure(bg=self.current_theme["bg_secondary"])
            if widget != self.title_bar:
                widget.configure(fg=self.current_theme["text_primary"])
                
        # Update main content
        content_labels = [self.img_label, self.counter_lbl, self.text_label]
        # include summary label as content label so its colors update
        content_labels.append(self.attach_summary_label)
        content_labels.append(self.status_label)
        for label in content_labels:
            label.configure(bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"])
            
        # Update frames
        frames = [self.btn_frame, self.img_bar]
        for frame in frames:
            frame.configure(bg=self.current_theme["bg_primary"])
            
        # Update canvas
        self.canvas.configure(bg=self.current_theme["bg_tertiary"], 
                            highlightbackground=self.current_theme["border"])
        self._draw_placeholder()
        
        # Update text input
        self.text_input.configure(bg=self.current_theme["bg_tertiary"], 
                                fg=self.current_theme["text_primary"],
                                insertbackground=self.current_theme["accent_blue"])
        
        # Update buttons with appropriate colors
        self.add_btn.configure(bg=self.current_theme["accent_blue"], 
                              fg=self.current_theme["text_primary"])
        self.remove_btn.configure(bg=self.current_theme["accent_red"], 
                                fg=self.current_theme["text_primary"])
        self.prev_btn.configure(bg=self.current_theme["bg_secondary"], 
                               fg=self.current_theme["text_primary"])
        self.next_btn.configure(bg=self.current_theme["bg_secondary"], 
                               fg=self.current_theme["text_primary"])
        self.clear_btn.configure(bg=self.current_theme["bg_secondary"], 
                                fg=self.current_theme["text_primary"])
        self.send_btn.configure(bg=self.current_theme["accent_green"], 
                               fg=self.current_theme["text_primary"])
        self.send_close_btn.configure(bg=self.current_theme["accent_blue"], 
                                     fg=self.current_theme["text_primary"])
        self.refine_btn.configure(bg=self.current_theme["accent_orange"], fg=self.current_theme["text_primary"])
        # Update checkboxes and terminal button
        try:
            self.include_context_chk.configure(bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"], selectcolor=self.current_theme["bg_primary"])
            self.include_project_chk.configure(bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"], selectcolor=self.current_theme["bg_primary"])
            self.include_archive_chk.configure(bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"], selectcolor=self.current_theme["bg_primary"])
            self.include_terminal_chk.configure(bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"], selectcolor=self.current_theme["bg_primary"])
            self.terminal_ctx_btn.configure(bg=self.current_theme["bg_secondary"], fg=self.current_theme["text_primary"])
        except Exception:
            pass

    def _on_toggle_include_context(self) -> None:
        state = tk.NORMAL if self.include_context_var.get() else tk.DISABLED
        try:
            self.include_project_chk.config(state=state)
            self.include_archive_chk.config(state=state)
            self.include_terminal_chk.config(state=state)
            self.terminal_ctx_btn.config(state=state)
        except Exception:
            pass

    def _open_terminal_context_dialog(self) -> None:
        try:
            txt = self._ask_terminal_context() or ""
            self.terminal_context_buffer = txt
            if txt:
                self.status_var.set("✅ Terminal context loaded")
            else:
                self.status_var.set("ℹ No terminal context provided")
        except Exception:
            self.status_var.set("")

    def _on_key_release(self, event) -> None:  # noqa: N802
        """Detect '@' key to trigger file autocomplete popup."""
        if event.char == "@":
            self._show_file_autocomplete()

        # Debounced snippet detection – run at most once per second
        now = time.time()
        last = getattr(self, "_last_snippet_scan", 0)
        if now - last > 1.0:
            self._last_snippet_scan = now
            threading.Thread(target=self._detect_snippet_files_thread).start()

        # Live extraction of @file mentions to update summary
        self._extract_mentioned_files()

    def _show_file_autocomplete(self) -> None:
        """Stateful autocomplete popup for '@' mentions with dynamic filtering."""
        # Ensure popup exists
        self._ensure_ac_popup()
        # Position it under the cursor
        self._position_ac_popup()
        # Build master list if empty
        if not self._ac_entries:
            try:
                items: list[str] = []
                for root, dirs, files in os.walk(self.app_dir):
                    # Skip internal config folder contents beyond top-level
                    if os.path.basename(root) == "MagicInput" and root != self.app_dir:
                        continue
                    # Only show relative to app_dir
                    rel_root = os.path.relpath(root, self.app_dir)
                    # Top-level include files/dirs, and shallow subdirs/files (limit depth to 2)
                    depth = 0 if rel_root == "." else rel_root.count(os.sep) + 1
                    if depth > 2:
                        continue
                    for d in dirs:
                        rel = os.path.normpath(os.path.join(rel_root, d)) if rel_root != "." else d
                        items.append(rel + os.sep)
                    for fn in files:
                        rel = os.path.normpath(os.path.join(rel_root, fn)) if rel_root != "." else fn
                        items.append(rel)
                # Deduplicate and sort
                seen = set()
                dedup: list[str] = []
                for it in items:
                    if it not in seen:
                        seen.add(it)
                        dedup.append(it)
                dedup.sort(key=lambda s: (s.count(os.sep), s.lower()))
                self._ac_entries = dedup
            except Exception:
                self._ac_entries = []
        # Update listbox based on current token
        self._update_ac_listbox()
        # Show and focus
        if self._ac_popup is not None:
            self._ac_popup.deiconify()
        # Keep typing focus in the text input so the popup doesn't block typing
        try:
            self.text_input.focus_set()
        except Exception:
            pass

    def _ensure_ac_popup(self) -> None:
        if self._ac_popup and self._ac_listbox:
            return
        self._ac_popup = tk.Toplevel(self.root)
        self._ac_popup.overrideredirect(True)
        # Keep popup above but never take focus
        try:
            self._ac_popup.attributes("-topmost", True)
            self._ac_popup.transient(self.root)
        except Exception:
            pass
        self._ac_popup.configure(bg=self.current_theme["bg_primary"])
        self._ac_listbox = tk.Listbox(
            self._ac_popup,
            bg=self.current_theme["bg_tertiary"],
            fg=self.current_theme["text_primary"],
            selectbackground=self.current_theme["accent_blue"],
            activestyle="none",
            exportselection=False,
            takefocus=0,
        )
        self._ac_listbox.pack(fill=tk.BOTH, expand=True)

        # Bindings
        self._ac_listbox.bind("<Escape>", lambda e: self._close_ac_popup())
        self._ac_listbox.bind("<Double-Button-1>", lambda e: self._insert_ac_selection())
        self._ac_listbox.bind("<Return>", lambda e: self._insert_ac_selection())
        self._ac_listbox.bind("<Button-1>", lambda e: None)
        # If the popup or listbox ever gains focus, return it to text_input
        self._ac_popup.bind("<FocusIn>", lambda e: self.text_input.focus_set())
        self._ac_listbox.bind("<FocusIn>", lambda e: self.text_input.focus_set())
        # Handle navigation keys at text widget level too
        self.text_input.bind("<Escape>", lambda e: (self._close_ac_popup(), "break"))
        self.text_input.bind("<Down>", lambda e: (self._move_ac_selection(1), "break") if self._ac_popup else None)
        self.text_input.bind("<Up>", lambda e: (self._move_ac_selection(-1), "break") if self._ac_popup else None)
        self.text_input.bind("<Return>", lambda e: (self._insert_ac_selection(), "break") if self._ac_popup else None)

    def _position_ac_popup(self) -> None:
        bbox = self.text_input.bbox(tk.INSERT)
        if bbox:
            x, y, width, height = bbox
            widget_x = self.text_input.winfo_rootx()
            widget_y = self.text_input.winfo_rooty()
            w, h = 320, 180
            self._ac_popup.geometry(f"{w}x{h}+{widget_x + x}+{widget_y + y + height}")
        else:
            widget_x = self.text_input.winfo_rootx()
            widget_y = self.text_input.winfo_rooty()
            self._ac_popup.geometry(f"320x180+{widget_x}+{widget_y+40}")

    def _current_at_token(self) -> tuple[str | None, str | None]:
        """Return (start_index, token_text) for the current '@' token before insert, else (None, None)."""
        try:
            idx = self.text_input.index(tk.INSERT)
            line_start = self.text_input.index(f"{idx} linestart")
            text_before = self.text_input.get(line_start, idx)
            m = re.search(r"@([\w./\\-]*)$", text_before)
            if m:
                start = f"{idx} - {len(m.group(0))}c"
                return start, m.group(1)
        except Exception:
            pass
        return None, None

    def _update_ac_listbox(self) -> None:
        start, partial = self._current_at_token()
        self._ac_start_index = start
        # Filter entries
        filtered: list[str] = []
        needle = (partial or "").lower()
        for it in self._ac_entries:
            if needle in it.lower():
                filtered.append(it)
        # Populate listbox
        if self._ac_listbox is None:
            return
        self._ac_listbox.delete(0, tk.END)
        for it in filtered[:200]:
            icon = "📁 " if it.endswith(os.sep) else "📄 "
            display = it.replace("\\", "/")
            self._ac_listbox.insert(tk.END, icon + display)
        # Select first item by default
        if filtered:
            self._ac_listbox.selection_set(0)
            self._ac_listbox.activate(0)
        else:
            # If nothing to show, hide popup
            self._close_ac_popup()

    def _move_ac_selection(self, delta: int) -> None:
        if not self._ac_listbox:
            return
        try:
            cur = self._ac_listbox.curselection()
            if not cur:
                idx = 0
            else:
                idx = cur[0] + delta
            idx = max(0, min(self._ac_listbox.size() - 1, idx))
            self._ac_listbox.selection_clear(0, tk.END)
            self._ac_listbox.selection_set(idx)
            self._ac_listbox.activate(idx)
            self._ac_listbox.see(idx)
        except Exception:
            pass

    def _insert_ac_selection(self) -> None:
        if not self._ac_listbox:
            return
        try:
            raw = self._ac_listbox.get(tk.ACTIVE)
            selection = raw[2:] if raw.startswith(("📁", "📄")) else raw
            # Replace the '@' token range with full selection
            if self._ac_start_index:
                self.text_input.delete(self._ac_start_index, tk.INSERT)
                # Ensure paths are in OS style
                token = selection
                if token.endswith("/") or token.endswith("\\"):
                    token = token.rstrip("/\\")
                # IMPORTANT: keep the '@' so mentions remain detectable
                self.text_input.insert(tk.INSERT, "@" + token)
            else:
                self.text_input.insert(tk.INSERT, "@" + selection)
            # After insertion, sync mentioned files
            self._extract_mentioned_files()
        except Exception:
            pass
        finally:
            self._close_ac_popup()

    def _close_ac_popup(self) -> None:
        try:
            if self._ac_popup is not None:
                self._ac_popup.destroy()
        except Exception:
            pass
        self._ac_popup = None
        self._ac_listbox = None
        self._ac_entries = []
        self._ac_start_index = None

    def _on_key_release(self, event) -> None:  # noqa: N802
        """Key handler to trigger and update '@' autocomplete and close logic."""
        try:
            # Close popup on whitespace or punctuation that ends tokens
            if event.keysym in {"Escape"}:
                self._close_ac_popup()
                return
            # If pressed '@' or we are within an '@' token, show/update popup
            start, partial = self._current_at_token()
            if start is not None:
                # Ensure popup visible and update
                self._show_file_autocomplete()
            else:
                # No token, close if open
                if self._ac_popup is not None:
                    self._close_ac_popup()

            # Debounced snippet detection – run at most once per second
            now = time.time()
            last = getattr(self, "_last_snippet_scan", 0)
            if now - last > 1.0:
                self._last_snippet_scan = now
                threading.Thread(target=self._detect_snippet_files_thread).start()

            # Live extraction of @file mentions to update summary
            self._extract_mentioned_files()
        except Exception:
            pass

    def _detect_snippet_files_thread(self) -> None:
        """Try to locate files in the codebase that contain the pasted snippet and add them as attachments."""
        snippet = self.text_input.get("1.0", tk.END).strip()
        # Skip if snippet too short
        if len(snippet) < 15:
            return

        matches: list[str] = []
        for root, _dirs, files in os.walk(self.app_dir):
            # Skip the internal .MagicInput directory
            if os.path.basename(root) == "MagicInput":
                continue
            for name in files:
                path = os.path.join(root, name)
                # Limit to text-like files < 1MB to keep things responsive
                try:
                    if os.path.getsize(path) > 1_000_000:
                        continue
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        if snippet in f.read():
                            matches.append(path)
                except Exception:
                    continue
        if not matches:
            return
        selected: str | None = None
        if len(matches) == 1:
            selected = matches[0]
        else:
            # Ask user to choose (this needs to be on the main thread)
            self.root.after(0, lambda: self._ask_user_to_choose_file_and_process(matches, snippet))
            return

        if selected and selected not in self.file_paths:
            self.file_paths.append(selected)
            # calculate meta for selected
            try:
                with open(selected, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                total_lines = content.count("\n") + 1
                idx = content.find(snippet)
                if idx != -1:
                    pre = content[:idx]
                    start_line = pre.count("\n") + 1
                    snippet_line_count = snippet.count("\n") + 1
                    end_line = start_line + snippet_line_count - 1
                    self.file_meta[selected] = (start_line, end_line, total_lines)
                    # Replace snippet in UI with mention (on main thread)
                    self.root.after(0, lambda: self._replace_snippet_with_mention(snippet, selected, self.file_meta[selected]))
            except Exception:
                pass

            self.root.after(0, self._refresh_summary)

    def _ask_user_to_choose_file_and_process(self, matches: list[str], snippet: str) -> None:
        selected = self._ask_user_to_choose_file(matches)
        if selected and selected not in self.file_paths:
            self.file_paths.append(selected)
            try:
                with open(selected, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                total_lines = content.count("\n") + 1
                idx = content.find(snippet)
                if idx != -1:
                    pre = content[:idx]
                    start_line = pre.count("\n") + 1
                    snippet_line_count = snippet.count("\n") + 1
                    end_line = start_line + snippet_line_count - 1
                    self.file_meta[selected] = (start_line, end_line, total_lines)
                    self._replace_snippet_with_mention(snippet, selected, self.file_meta[selected])
            except Exception:
                pass
            self._refresh_summary()

    def _extract_mentioned_files(self) -> None:
        """Synchronise self.file_paths with the @file mentions currently present in the text box."""
        text = self.text_input.get("1.0", tk.END)

        # Gather all mentioned file tokens (could be absolute or relative)
        mentioned_tokens = re.findall(r"@([\w./\\-]+)", text)
        mentioned_abs: set[str] = set()
        for token in mentioned_tokens:
            if os.path.isabs(token):
                mentioned_abs.add(os.path.abspath(token))
            else:
                mentioned_abs.add(os.path.abspath(os.path.join(self.app_dir, token)))

        # Add newly mentioned files
        for abs_path in mentioned_abs:
            if os.path.isfile(abs_path) and abs_path not in self.file_paths:
                self.file_paths.append(abs_path)

        # Remove files no longer mentioned
        for existing in self.file_paths[:]:
            if existing not in mentioned_abs:
                self.file_paths.remove(existing)
                self.file_meta.pop(existing, None)

        # Finally refresh summary bar
        self._refresh_summary()

    def _ask_user_to_choose_file(self, options: list[str]) -> str | None:
        """Popup list for user to choose one of the matching files."""
        popup = tk.Toplevel(self.root)
        popup.title("Select matching file")
        popup.configure(bg=self.current_theme["bg_primary"])
        popup.geometry("400x250")
        lb = tk.Listbox(popup, bg=self.current_theme["bg_tertiary"], fg=self.current_theme["text_primary"],
                        selectbackground=self.current_theme["accent_blue"], highlightthickness=0)
        lb.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        for path in options:
            lb.insert(tk.END, path)

        chosen: list[str] = []

        def _choose(event=None):
            sel = lb.get(tk.ACTIVE)
            if sel:
                chosen.append(sel)
            popup.destroy()

        lb.bind("<Double-Button-1>", _choose)
        lb.bind("<Return>", _choose)
        lb.focus_set()
        popup.bind("<Escape>", lambda e: popup.destroy())
        popup.wait_window()
        return chosen[0] if chosen else None

    def _replace_snippet_with_mention(self, snippet: str, file_path: str, meta: tuple[int, int, int]):
        """Replace the first occurrence of the snippet in the text box with a formatted mention line."""
        s_line, e_line, total = meta
        # Build preview words
        words = snippet.strip().split()
        first_two = " ".join(words[:2])
        last_two = " ".join(words[-2:]) if len(words) > 2 else ""
        preview = f"{first_two} … {last_two}" if last_two else first_two
        # Include the relative path so the directory link is visible to the user
        rel_path = os.path.relpath(file_path, self.app_dir)
        mention_line = f"[@{rel_path} ({s_line}-{e_line}/{total}) «{preview}»]"

        # Use Tk search to locate snippet text
        pos = self.text_input.search(snippet, "1.0", tk.END)
        if pos:
            end_pos = f"{pos}+{len(snippet)}c"
            self.text_input.delete(pos, end_pos)
            self.text_input.insert(pos, mention_line)

            # Ensure summary bar refreshes
            self._extract_mentioned_files()
            self._refresh_summary()

    def _insert_image_mention(self, img_path: str) -> None:
        """Insert an image mention tag at the current cursor location."""
        # Show the relative path (inside MagicInput) so users can click/see the directory link
        rel_path = os.path.relpath(img_path, self.app_dir)
        mention = f"[🖼 {rel_path}]"
        self.text_input.insert(tk.INSERT, mention + "\n")

    def _insert_file_mention(self, file_path: str) -> None:
        """Insert a file mention tag (with path) at the current cursor location."""
        rel_path = os.path.relpath(file_path, self.app_dir)
        self.text_input.insert(tk.INSERT, f"[@{rel_path}]\n")

    def _refine_prompt(self) -> None:
        """Use Gemini AI to rewrite/refine the current prompt text."""
        if not self.api_key:
            self.root.after(0, lambda: messagebox.showwarning("Gemini API","Gemini AI not configured. Please set the API key via Settings (⚙) or GEMINI_API_KEY env var."))
            return
        original = self.text_input.get("1.0", tk.END).strip()
        if not original:
            return

        self.refine_btn.config(state=tk.DISABLED)
        self.root.config(cursor="wait")
        self.root.update()

        # Run the refinement in a separate thread
        threading.Thread(target=self._refine_prompt_thread, args=(original,)).start()

    def _refine_prompt_thread(self, original_prompt: str) -> None:
        context_parts: list[str] = []
        for idx, _ in enumerate(self.images):
            context_parts.append(f"Image {idx+1} attached")
        for p in self.file_paths:
            try:
                with open(p, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                context_parts.append(f"File: {os.path.basename(p)}\n---\n{content}\n---")
            except Exception:
                continue
        context_block = "\n\n".join(context_parts) if context_parts else ""

        try:
            prompt_text = (
                "You are a prompt engineer. Rewrite the USER_PROMPT into a crisp, executable prompt that explicitly captures the user's goal and context. "
                "Use ONLY the information supplied (USER_PROMPT and ATTACHMENT_CONTEXT). Do NOT assume or hallucinate missing details. "
                "If critical information is missing, include short TODO placeholders. Output ONLY the refined prompt, with no extra commentary.\n\n"
                "Required structure for the refined prompt:\n"
                "- Primary Goal: <one-sentence goal in user's terms>\n"
                "- Desired Outcome: <concrete deliverable(s)>\n"
                "- Success Criteria: <bulleted, measurable checks>\n"
                "- Constraints & Preferences: <tools, style, platform, scope, timing>\n"
                "- Non-Goals: <items out of scope if implied>\n"
                "- Context (attachments): <brief, cite sources e.g., [File: name.ext (lines a-b)]>\n"
                "- Unknowns / TODO: <bulleted open questions>\n"
                "- Instruction: <clear instruction to the assistant on what to produce next>\n\n"
                f"USER_PROMPT:\n{original_prompt}\n\n" + (f"ATTACHMENT_CONTEXT:\n{context_block}" if context_block else "")
            )

            refined = None
            if not self.client:
                self.root.after(0, lambda: messagebox.showerror("Gemini Error", "Gemini client not configured. Please set API key."))
                return
            
            contents = cast(Any, [
                types.Content(role="user", parts=[types.Part.from_text(text=prompt_text)])
            ])
            cfg = types.GenerateContentConfig(response_mime_type="text/plain")
            # Attempt streaming with failover on rate limit
            def _stream_call():
                return self.client.models.generate_content_stream(model=self.model_name, contents=contents, config=cfg)  # type: ignore[arg-type]

            refined_parts: list[str] = []
            attempt = 0
            max_attempts = max(1, len(self.api_keys))
            while attempt < max_attempts:
                try:
                    chunks = _stream_call()
                    for ch in chunks:
                        txt = getattr(ch, "text", None)
                        if txt:
                            refined_parts.append(txt)
                    break
                except Exception as e:
                    if self._is_rate_limit_error(e) and self._rotate_api_key():
                        attempt += 1
                        continue
                    raise
            refined = "".join(refined_parts)

            if not refined:
                refined = original_prompt
            
            # Update UI on the main thread
            self.root.after(0, lambda: self._update_refined_prompt_ui(refined))

        except Exception as e:
            try:
                self.root.after(0, lambda err=e: messagebox.showerror("Gemini Error", f"Failed to refine prompt: {err}"))
            except:
                pass
        finally:
            try:
                self.root.after(0, lambda: self.refine_btn.config(state=tk.NORMAL))
                self.root.after(0, lambda: self.root.config(cursor=""))
            except:
                pass

    def _update_refined_prompt_ui(self, refined_text: str) -> None:
        self.text_input.delete("1.0", tk.END)
        self.text_input.insert("1.0", refined_text)

    def _describe_image(self) -> None:
        if not self.api_key:
            self.root.after(0, lambda: messagebox.showwarning("Gemini API","Gemini AI not configured. Please set the API key via Settings (⚙) or GEMINI_API_KEY env var."))
            return
        # Visionize now works with or without images - it can analyze files/codes/prompt
        if not self.images and not self.file_paths and not self.text_input.get("1.0", tk.END).strip():
            self.root.after(0, lambda: messagebox.showwarning("Visionize","Please add an image, attach files, or enter a prompt to analyze."))
            return

        user_prompt = self.text_input.get("1.0", tk.END).strip()
        if not user_prompt:
            user_prompt = "Describe this image in detail."

        # Collect enhanced context if enabled
        enhanced_context = {}
        include_ctx = bool(self.include_context_var.get())
        if include_ctx:
            try:
                # 1. Collect project brief files automatically (if enabled)
                if not hasattr(self, 'include_project_var') or bool(self.include_project_var.get()):
                    enhanced_context['project_brief'] = self._collect_project_brief_context(max_chars=15000)

                # 2. Collect prompts archive for continuity (if enabled)
                if not hasattr(self, 'include_archive_var') or bool(self.include_archive_var.get()):
                    enhanced_context['prompts_archive'] = self._read_prompts_archive(max_chars=10000)

                # 3. Terminal context (if enabled)
                terminal_text = ""
                if not hasattr(self, 'include_terminal_var') or bool(self.include_terminal_var.get()):
                    # Prefer preloaded buffer, otherwise ask
                    terminal_text = getattr(self, 'terminal_context_buffer', "").strip()
                    if not terminal_text:
                        terminal_text = self._ask_terminal_context() or ""
                        self.terminal_context_buffer = terminal_text
                enhanced_context['terminal_context'] = terminal_text

            except Exception:
                # If enhanced context collection fails, continue with basic functionality
                enhanced_context = {'terminal_context': ''}

        self.visionize_btn.config(state=tk.DISABLED)
        self.root.config(cursor="wait")
        self.root.update()

        try:
            mode = self.mode_var.get()
        except Exception:
            mode = "plan"
        threading.Thread(target=self._describe_image_thread, args=(mode, user_prompt, include_ctx, enhanced_context)).start()

    def _describe_image_thread(self, mode: str, user_prompt: str, include_context: bool, enhanced_context: dict) -> None:
        try:
            if not self.client:
                self._log_debug("Gemini client not configured. API key missing or client init failed.")
                self.root.after(0, lambda: messagebox.showerror("Gemini Error", "Gemini client not configured. Please set API key."))
                return
            
            image_parts = []
            image_sizes: list[int] = []
            errors: list[str] = []
            self._log_debug(f"Starting image processing for {len(self.images)} image(s). include_context={include_context}; mode={mode}")
            for item in list(self.images):
                try:
                    data = item.get("bytes", b"")
                    if not data:
                        errors.append("Empty image bytes encountered")
                        continue
                    image_sizes.append(len(data))
                    image_parts.append(types.Part.from_bytes(data=data, mime_type='image/png'))
                except Exception as e:
                    name = item.get("name", "<image>")
                    err_msg = f"Failed processing '{name}': {e}"
                    errors.append(err_msg)
                    self._log_debug(err_msg, e)
                    continue
            self._log_debug(f"Prepared {len(image_parts)} image part(s). total_bytes={sum(image_sizes)} sizes={image_sizes}")
            
            # If no images but we have files or prompt, continue with text-only analysis
            has_content_to_analyze = bool(image_parts or self.file_paths or user_prompt.strip())
            
            if not has_content_to_analyze:
                self.root.after(0, lambda: messagebox.showwarning("Visionize", "No content to analyze. Please add images, attach files, or enter a prompt."))
                return
            
            # If image processing failed but we have other content, log and continue
            if not image_parts and errors and self.images:
                summary = "\n".join(f"- {e}" for e in errors[:3])
                self._log_debug(f"Image processing errors (continuing with text analysis): {summary}")
                # Don't return - continue with file/text analysis

            # Build comprehensive context
            context_parts = []
            
            if include_context:
                # Add project brief context
                if enhanced_context.get('project_brief'):
                    context_parts.append(f"=== PROJECT OVERVIEW ===\n{enhanced_context['project_brief']}")
                
                # Add prompts archive for continuity
                if enhanced_context.get('prompts_archive'):
                    context_parts.append(f"=== PREVIOUS INTERACTIONS ===\n{enhanced_context['prompts_archive']}")
                
                # Add terminal context if provided
                if enhanced_context.get('terminal_context'):
                    context_parts.append(f"=== TERMINAL OUTPUT ===\n{enhanced_context['terminal_context']}")
            
            # Debug: log context inclusion and sizes
            proj_len = len(enhanced_context.get('project_brief') or '')
            arch_len = len(enhanced_context.get('prompts_archive') or '')
            term_len = len(enhanced_context.get('terminal_context') or '')
            self._log_debug(
                f"Context flags: include_context={include_context}; "
                f"project_brief={'yes' if bool(enhanced_context.get('project_brief')) else 'no'}({proj_len} chars); "
                f"prompts_archive={'yes' if bool(enhanced_context.get('prompts_archive')) else 'no'}({arch_len} chars); "
                f"terminal={'yes' if bool(enhanced_context.get('terminal_context')) else 'no'}({term_len} chars)"
            )

            # Add attached file context
            if self.file_paths:
                self._log_debug(f"Attached files detected: count={len(self.file_paths)}; names={[os.path.basename(p) for p in self.file_paths]}")
                file_contexts = []
                files_meta: list[tuple[str, int]] = []
                for p in self.file_paths:
                    try:
                        with open(p, "r", encoding="utf-8", errors="ignore") as f:
                            content = f.read()
                        # Include file metadata if available
                        meta = self.file_meta.get(p)
                        if meta:
                            s_line, e_line, total = meta
                            snippet = content[:2000]
                            file_contexts.append(f"File: {os.path.basename(p)} (lines {s_line}-{e_line}/{total})\n---\n{snippet}\n---")
                            files_meta.append((os.path.basename(p), len(snippet)))
                        else:
                            snippet = content[:2000]
                            file_contexts.append(f"File: {os.path.basename(p)}\n---\n{snippet}\n---")
                            files_meta.append((os.path.basename(p), len(snippet)))
                    except Exception:
                        continue
                if file_contexts:
                    context_parts.append(f"=== ATTACHED FILES ===\n\n{chr(10).join(file_contexts)}")
                    self._log_debug(f"Attached file snippet sizes (chars): {files_meta}")

            context_block = "\n\n".join(context_parts) if context_parts else ""
            self._log_debug(f"Context block total size={len(context_block)} chars; user_prompt size={len(user_prompt)} chars")
            
            # Choose prompt template based on mode (plan | describe | combine)
            sel_mode = (mode or "").lower()
            if sel_mode not in ("plan", "describe", "combine"):
                sel_mode = "plan"

            # Build required headings based on selection
            def _headings_for(m: str) -> list[str]:
                if m == "plan":
                    return ["## Overview", "## Plan"]
                if m == "describe":
                    return ["## Overview", "## Describe Image"]
                return ["## Overview", "## Describe Image", "## Plan"]

            headings = _headings_for(sel_mode)

            # Guidance per section (used in instructions; do not echo verbatim)
            overview_req = (
                "Write 2–4 sentences summarizing what the image(s) show and the intended purpose inferred from USER REQUEST. "
                "Keep it factual and task‑oriented; avoid fluff or speculation beyond the given CONTEXT."
            )
            describe_req = (
                "Provide a highly detailed, context‑aware description tailored to the USER REQUEST. If the task is UI/UX, cover layout, hierarchy, states, components, labels, icons, colors, typography, spacing, and affordances. "
                "If the task is debugging/implementation/backend, focus on visible workflows, data/values, architectural hints, logs/console outputs, and any code/UI cues relevant to functionality. "
                "Start with the user’s target area, then cover other relevant areas. Explicitly note uncertainties."
            )
            plan_req = (
                "Provide a concise, actionable plan connected to the description (5–10 bullets). Each bullet should state what to do, why it matters, and the expected impact. "
                "Scope the actions to this project/app and align them with the USER REQUEST (may include UI changes, debugging steps, code changes, tests, or backend tasks)."
            )

            headings_block = "\n\n".join(headings)

            analysis_prompt = f"""
You are a senior software engineer and product‑minded builder analyzing the provided image(s) for the USER REQUEST using the given CONTEXT. Do not hallucinate.

Analyze ALL available inputs:
1) The image(s) provided.
2) The INCLUDED CONTEXT below which may contain: a project brief with listed files and snippets, the prompts archive, and terminal logs or outputs.
Always incorporate relevant evidence from these sources; do not ignore them.

=== USER REQUEST ===
{user_prompt}

{context_block}

Write the answer in Markdown with EXACTLY the following section headings (and nothing else), in this order:

{headings_block}

Content requirements (adapt based on the nature of the USER REQUEST—UI/UX, debugging, backend functionality, feature implementation, or anything else what asking the user):
- Overview: {overview_req}
- Describe Image: {describe_req if '## Describe Image' in headings else 'Skip this section entirely.'}
- Plan: {plan_req if '## Plan' in headings else 'Skip this section entirely.'}

Constraints:
- Base everything strictly on the provided image(s) and CONTEXT. If something is unknown, state it briefly in the relevant section.
- If multiple images are provided, use “Image N:” prefixes where helpful and keep the final output within the same sections above.
"""

            # Create the API request with images and text
            parts = image_parts + [types.Part.from_text(text=analysis_prompt)]
            self._log_debug(f"Calling Gemini with {len(image_parts)} image part(s). Model={self.model_name}")
            def _call():
                return self.client.models.generate_content(
                    model=self.model_name,
                    contents=[types.Content(parts=parts)]
                )
            response = self._with_key_failover(_call)
            self._log_debug("Gemini response received successfully")

            description = response.text.strip() if response.text else ""
            if description:
                self.root.after(0, lambda: self._insert_description_into_text(description))
            else:
                self.root.after(0, lambda: messagebox.showwarning("Image Description", "No description generated."))

        except Exception as e:
            self._log_debug("Describe image thread encountered an error.", e)
            try:
                self.root.after(0, lambda err=e: messagebox.showerror("Gemini Error", f"Failed to describe image: {err}"))
            except:
                pass
        finally:
            try:
                self.root.after(0, lambda: self.visionize_btn.config(state=tk.NORMAL))
                self.root.after(0, lambda: self.root.config(cursor=""))
            except:
                pass

    # -------------------------- Prompt persistence & countdown helpers --------------------------
    def _init_waiting_prompt(self, seconds: int = 30) -> None:
        """Write waiting placeholder and start an infinite count-up from 0s."""
        try:
            with open(self.prompt_log_path, "w", encoding="utf-8") as f:
                f.write(self.waiting_placeholder)
        except Exception:
            pass
        # Initialize count-up timer
        self._countup_elapsed = 0
        self.status_var.set("⏳ Waiting for prompt: 0s")
        self._start_countup()

    def _start_countup(self) -> None:
        """Start an infinite count-up timer that updates every second until cancelled."""
        def _tick():
            elapsed = getattr(self, "_countup_elapsed", 0)
            self.status_var.set(f"⏳ Waiting for prompt: {elapsed}s")
            self._countup_elapsed = elapsed + 1
            self._countdown_after_id = self.root.after(1000, _tick)
        self._countdown_after_id = self.root.after(0, _tick)

    def _persist_prompt(self, new_text: str) -> None:
        """Keep only the last prompt in MagicInput Prompt.txt and move previous to Prompts Archive.txt."""
        prev = ""
        try:
            if os.path.isfile(self.prompt_log_path):
                with open(self.prompt_log_path, "r", encoding="utf-8", errors="ignore") as f:
                    prev = f.read().strip()
        except Exception:
            prev = ""

        # Prepend previous prompt to archive (top instead of bottom) if it isn't the waiting placeholder and not empty
        if prev and prev != self.waiting_placeholder:
            try:
                sep = "\n" + ("-" * 50) + "\n"
                timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                new_entry = f"[{timestamp}]\n{prev}{sep}"
                
                # Read existing archive content
                existing_content = ""
                try:
                    if os.path.isfile(self.archive_path):
                        with open(self.archive_path, "r", encoding="utf-8", errors="ignore") as f:
                            existing_content = f.read()
                except Exception:
                    existing_content = ""
                
                # Write new entry at top, then existing content
                with open(self.archive_path, "w", encoding="utf-8") as arch:
                    arch.write(new_entry + existing_content)
            except Exception:
                pass

        # Overwrite with new
        with open(self.prompt_log_path, "w", encoding="utf-8") as f:
            f.write(new_text)

    # -------------------------- Context collection helpers --------------------------
    def _collect_project_brief_context(self, max_chars: int = 20000) -> str:
        """Collects content from common brief/overview files in the project root and docs/."""
        candidates = {
            "readme.md", "readme.txt",
            "plan.md", "plan.txt",
            "task.md", "task.txt",
            "mtask.md", "mtask.txt",
            "roadmap.md", "roadmap.txt",
            "overview.md", "overview.txt",
            "design.md", "design.txt",
            "requirements.md", "requirements.txt",
            "contributing.md", "changelog.md", "changelog.txt",
        }
        blocks: list[str] = []
        # Root files
        for name in os.listdir(self.app_dir):
            path = os.path.join(self.app_dir, name)
            if os.path.isfile(path) and name.lower() in candidates:
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                    blocks.append(f"# {name}\n{content}\n")
                except Exception:
                    continue
        # docs/ directory (shallow)
        docs_dir = os.path.join(self.app_dir, "docs")
        if os.path.isdir(docs_dir):
            try:
                for name in os.listdir(docs_dir):
                    if not name.lower().endswith((".md", ".txt")):
                        continue
                    path = os.path.join(docs_dir, name)
                    if os.path.isfile(path):
                        with open(path, "r", encoding="utf-8", errors="ignore") as f:
                            content = f.read()
                        blocks.append(f"# docs/{name}\n{content}\n")
            except Exception:
                pass
        joined = "\n\n".join(blocks)
        return joined[:max_chars]

    def _read_prompts_archive(self, max_chars: int = 20000) -> str:
        try:
            if os.path.isfile(self.archive_path):
                with open(self.archive_path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                # Keep the last segment if too large
                if len(content) > max_chars:
                    return content[-max_chars:]
        except Exception:
            pass
        return ""

    def _list_open_terminals_windows(self) -> list[tuple[int, str, str]]:
        """Enumerate open terminal-like windows on Windows.

        Returns a list of tuples: (hwnd, window_title, class_name)
        """
        if platform.system() != 'Windows':
            return []

        results: list[tuple[int, str, str]] = []

        # Known terminal window classes and title hints
        terminal_classes = {
            # Classic console (cmd, legacy powershell)
            "ConsoleWindowClass",
            # Windows Terminal is an AppFrame; title contains Windows Terminal
            "ApplicationFrameWindow",
            # ConEmu
            "VirtualConsoleClass",
            "ConEmuMainClass",
            # Alacritty
            "GLFW30",
            # mintty (Git Bash, Cygwin)
            "mintty",
        }
        title_hints = (
            "cmd", "command prompt", "powershell", "pwsh", "windows terminal",
            "git bash", "wsl", "ubuntu", "debian", "alacritty", "conemu", "cygwin", "mintty"
        )

        GetClassNameW = ctypes.windll.user32.GetClassNameW
        GetWindowTextLengthW = ctypes.windll.user32.GetWindowTextLengthW
        GetWindowTextW = ctypes.windll.user32.GetWindowTextW
        IsWindowVisible = ctypes.windll.user32.IsWindowVisible

        EnumWindows = ctypes.windll.user32.EnumWindows
        EnumWindowsProc = ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)

        def callback(hwnd, lParam):
            try:
                if not IsWindowVisible(hwnd):
                    return True
                # Title
                length = GetWindowTextLengthW(hwnd)
                if length == 0:
                    title = ""
                else:
                    buf = ctypes.create_unicode_buffer(length + 1)
                    GetWindowTextW(hwnd, buf, length + 1)
                    title = buf.value or ""
                # Class
                cls_buf = ctypes.create_unicode_buffer(256)
                GetClassNameW(hwnd, cls_buf, 256)
                cls_name = cls_buf.value or ""

                title_l = title.lower()
                cls_l = cls_name.lower()

                if cls_name in terminal_classes or any(h in title_l for h in title_hints):
                    results.append((int(hwnd), title, cls_name))
            except Exception:
                pass
            return True

        try:
            EnumWindows(EnumWindowsProc(callback), 0)
        except Exception:
            # If EnumWindows fails, return whatever collected
            pass
        return results

    def _ask_terminal_context(self) -> str | None:
        """Popup that lists open terminals (Windows) and lets user paste or attach logs."""
        popup = tk.Toplevel(self.root)
        popup.title("Add Terminal Context (optional)")
        popup.configure(bg=self.current_theme["bg_primary"])
        popup.geometry("720x420")

        outer = tk.Frame(popup, bg=self.current_theme["bg_primary"])
        outer.pack(fill=tk.BOTH, expand=True)

        # Left: terminal list (Windows only)
        left = tk.Frame(outer, bg=self.current_theme["bg_primary"])
        left.pack(side=tk.LEFT, fill=tk.Y, padx=(10, 6), pady=10)
        tk.Label(left, text="Open terminals (Windows):", bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"]).pack(anchor="w")
        term_list = tk.Listbox(left, height=14, width=36, activestyle="dotbox")
        term_list.pack(fill=tk.Y, expand=False, pady=(4, 6))

        actions = tk.Frame(left, bg=self.current_theme["bg_primary"])
        actions.pack(fill=tk.X)
        def _refresh():
            term_list.delete(0, tk.END)
            items = self._list_open_terminals_windows() if platform.system() == 'Windows' else []
            for hwnd, title, cls in items:
                term_list.insert(tk.END, f"[{cls}] {title}  (hwnd={hwnd})")
            if not items:
                term_list.insert(tk.END, "No terminals detected. You can still paste or add from files.")
        def _activate():
            sel = term_list.curselection()
            if not sel:
                return
            line = term_list.get(sel[0])
            try:
                hwnd = int(line.rsplit("=",1)[-1].rstrip(")"))
                ctypes.windll.user32.SetForegroundWindow(hwnd)
            except Exception:
                pass
        tk.Button(actions, text="Refresh", command=_refresh, bg=self.current_theme["bg_secondary"], fg=self.current_theme["text_primary"], relief="flat").pack(side=tk.LEFT)
        tk.Button(actions, text="Activate", command=_activate, bg=self.current_theme["bg_secondary"], fg=self.current_theme["text_primary"], relief="flat").pack(side=tk.LEFT, padx=(6,0))

        help_lbl = tk.Label(left,
            text="Tip: Activate a terminal, press Ctrl+A then Ctrl+C (or Ctrl+Shift+C),\nthen use 'Paste Clipboard' to insert here.",
            justify="left",
            bg=self.current_theme["bg_primary"], fg=self.current_theme["text_secondary"])
        help_lbl.pack(anchor="w", pady=(6,0))

        # Right: text editor
        right = tk.Frame(outer, bg=self.current_theme["bg_primary"])
        right.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=(6,10), pady=10)
        tk.Label(right, text="Terminal context:", bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"]).pack(anchor="w")
        # Improved readability: larger monospace font and themed caret
        txt = scrolledtext.ScrolledText(
            right,
            wrap=tk.WORD,
            height=15,
            bg=self.current_theme["bg_tertiary"],
            fg=self.current_theme["text_primary"],
            insertbackground=self.current_theme["accent_blue"],
            font=("Consolas", 11)
        )
        txt.pack(fill=tk.BOTH, expand=True, pady=(4, 6))

        # Configure keyword-specific tags
        txt.tag_config("kw_vector", foreground=self.current_theme["accent_purple"], font=("Consolas", 11, "bold"))
        txt.tag_config("kw_mockup", foreground=self.current_theme["accent_orange"], font=("Consolas", 11, "bold"))
        txt.tag_config("kw_rgb", foreground=self.current_theme["accent_blue"], font=("Consolas", 11, "bold"))
        txt.tag_config("kw_cmyk", foreground=self.current_theme["accent_blue"], font=("Consolas", 11, "bold"))
        txt.tag_config("kw_dpi", foreground=self.current_theme["accent_green"], font=("Consolas", 11, "bold"))
        txt.tag_config("kw_pantone", foreground=self.current_theme["accent_red"], font=("Consolas", 11, "bold"))

        def _highlight_keywords():
            try:
                # Clear existing keyword tags
                for tag in ("kw_vector", "kw_mockup", "kw_rgb", "kw_cmyk", "kw_dpi", "kw_pantone"):
                    txt.tag_remove(tag, "1.0", tk.END)

                patterns = [
                    ("vector tracing", "kw_vector"),
                    ("mockup", "kw_mockup"),
                    ("rgb", "kw_rgb"),
                    ("cmyk", "kw_cmyk"),
                    ("dpi", "kw_dpi"),
                    ("pantone", "kw_pantone"),
                ]

                for needle, tag in patterns:
                    start = "1.0"
                    while True:
                        idx = txt.search(needle, start, stopindex=tk.END, nocase=True)
                        if not idx:
                            break
                        end = f"{idx}+{len(needle)}c"
                        txt.tag_add(tag, idx, end)
                        start = end
            except Exception:
                pass

        # Bottom bar
        btn_bar = tk.Frame(right, bg=self.current_theme["bg_primary"])
        btn_bar.pack(fill=tk.X)
        def _paste_clipboard():
            try:
                data = popup.clipboard_get()
                if data:
                    txt.insert(tk.END, ("\n" if txt.get("1.0", tk.END).strip() else "") + data)
                    _highlight_keywords()
            except Exception:
                pass
        def _add_files():
            paths = filedialog.askopenfilenames(title="Select log/text files", filetypes=[["Text", "*.txt *.log *.md"], ["All", "*.*"]])
            for p in paths:
                try:
                    with open(p, "r", encoding="utf-8", errors="ignore") as f:
                        txt.insert(tk.END, f"\n\n# {os.path.basename(p)}\n" + f.read())
                        _highlight_keywords()
                except Exception:
                    pass
        tk.Button(btn_bar, text="Paste Clipboard", command=_paste_clipboard, bg=self.current_theme["bg_secondary"], fg=self.current_theme["text_primary"], relief="flat").pack(side=tk.LEFT)
        tk.Button(btn_bar, text="Add From Files…", command=_add_files, bg=self.current_theme["bg_secondary"], fg=self.current_theme["text_primary"], relief="flat").pack(side=tk.LEFT, padx=(6,0))

        chosen: list[str] = []
        def _ok():
            chosen.append(txt.get("1.0", tk.END).strip())
            popup.destroy()
        def _cancel():
            popup.destroy()
        tk.Button(btn_bar, text="Cancel", command=_cancel, bg=self.current_theme["bg_secondary"], fg=self.current_theme["text_primary"], relief="flat").pack(side=tk.RIGHT)
        tk.Button(btn_bar, text="OK", command=_ok, bg=self.current_theme["accent_blue"], fg=self.current_theme["text_primary"], relief="flat").pack(side=tk.RIGHT, padx=(6,0))

        # Highlight on edits as the user types/pastes
        txt.bind("<KeyRelease>", lambda e: _highlight_keywords())

        _refresh()
        popup.grab_set()
        txt.focus_set()
        # Initial highlight (no-op if empty)
        _highlight_keywords()
        popup.wait_window()
        return chosen[0] if chosen else None

    def _insert_description_into_text(self, description: str) -> None:
        current_text = self.text_input.get("1.0", tk.END).strip()
        
        # Format the description professionally
        formatted_description = (
            "\n\n## Analysis:\n"
            f"{description.strip()}\n"
            "\n---\n"
            "*Analysis Generated by AI*"
        )
        
        if current_text:
            self.text_input.insert(tk.END, formatted_description)
        else:
            # If no text exists, add a basic prompt first
            self.text_input.insert(tk.END, "Analyze the attached image." + formatted_description)
        
        self.text_input.see(tk.END)  # Scroll to end

    # Add config load/save and settings dialog methods near other helpers
    def _load_config(self):
        try:
            if os.path.isfile(self.config_path):
                with open(self.config_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                # Load multi-key set (fallback to single key)
                keys = data.get("gemini_api_keys")
                if isinstance(keys, list) and keys:
                    self.api_keys = [k for k in keys if isinstance(k, str) and k.strip()]
                    self.active_key_index = int(data.get("active_key_index", 0)) if self.api_keys else 0
                    self.api_key = (self.api_keys[self.active_key_index]
                                    if self.api_keys and 0 <= self.active_key_index < len(self.api_keys)
                                    else None)
                else:
                    self.api_key = data.get("gemini_api_key")
                    if self.api_key:
                        self.api_keys = [self.api_key]
                        self.active_key_index = 0
                # Model name
                self.model_name = data.get("model", self.model_name)
                self.auto_refine = data.get("auto_refine", False)
                # Load UI preferences if present
                try:
                    prefs = data.get("ui_prefs", {})
                    # Theme
                    theme = prefs.get("theme")
                    if theme in ("dark", "light"):
                        desired_dark = (theme == "dark")
                        if desired_dark != getattr(self, "is_dark_theme", True):
                            # Toggle to desired theme
                            self._toggle_theme()
                    # Mode (supports legacy 'connections' -> 'plan')
                    mode = prefs.get("mode")
                    if mode == "connections":
                        mode = "plan"
                    if mode in ("plan", "describe", "combine"):
                        try:
                            self.mode_var.set(mode)
                        except Exception:
                            pass
                    # Context toggles
                    try:
                        inc_ctx = bool(prefs.get("include_context", True))
                        self.include_context_var.set(inc_ctx)
                        self._on_toggle_include_context()
                    except Exception:
                        pass
                    try:
                        self.include_project_var.set(bool(prefs.get("include_project", True)))
                    except Exception:
                        pass
                    try:
                        self.include_archive_var.set(bool(prefs.get("include_archive", True)))
                    except Exception:
                        pass
                    try:
                        self.include_terminal_var.set(bool(prefs.get("include_terminal", True)))
                    except Exception:
                        pass
                    # Ensure preferences are persisted under ui_prefs section
                    try:
                        self._save_config()
                    except Exception:
                        pass
                except Exception:
                    pass
        except Exception:
            pass

    def _save_config(self):
        # Persist API/feature flags
        data = {
            "gemini_api_key": self.api_key,  # legacy compatibility
            "gemini_api_keys": self.api_keys,
            "active_key_index": self.active_key_index,
            "model": self.model_name,
            "auto_refine": self.auto_refine,
        }
        # Persist UI prefs
        try:
            ui_prefs = {
                "theme": "dark" if getattr(self, "is_dark_theme", True) else "light",
                "mode": getattr(self, "mode_var", tk.StringVar(value="plan")).get(),
                "include_context": bool(getattr(self, "include_context_var", tk.BooleanVar(value=True)).get()),
                "include_project": bool(getattr(self, "include_project_var", tk.BooleanVar(value=True)).get()),
                "include_archive": bool(getattr(self, "include_archive_var", tk.BooleanVar(value=True)).get()),
                "include_terminal": bool(getattr(self, "include_terminal_var", tk.BooleanVar(value=True)).get()),
            }
            data["ui_prefs"] = ui_prefs
        except Exception:
            pass
        try:
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(data, f)
        except Exception as e:
            messagebox.showerror("Config Error", f"Unable to save config: {e}")

    def _on_prefs_changed(self) -> None:
        """Save UI preferences immediately on change."""
        try:
            self._save_config()
        except Exception:
            pass

    def _open_settings(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("Settings")
        dialog.configure(bg=self.current_theme["bg_primary"])
        dialog.resizable(False, False)

        # Container frames
        wrap = tk.Frame(dialog, bg=self.current_theme["bg_primary"]) 
        wrap.pack(fill=tk.BOTH, expand=True, padx=12, pady=10)

        # ----- Model selection -----
        tk.Label(wrap, text="Model", bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"], font=(None, 10, "bold")).pack(anchor="w")
        models = [
            "gemini-2.5-flash",
            "gemini-2.5-flash-lite-preview-06-17",
            "gemini-2.5-flash-preview-05-20",
            "gemini-2.5-flash-preview-04-17",
            "gemini-2.0-flash",
            "gemini-2.0-flash-preview-image-generation",
            "gemini-1.5-flash",
            "gemini-1.5-pro",
            "gemini-1.5-flash-latest",
        ]
        model_var = tk.StringVar(value=self.model_name)
        model_combo = ttk.Combobox(wrap, textvariable=model_var, values=models, state="readonly")
        model_combo.pack(fill=tk.X, pady=(2, 10))

        # ----- API keys (multi) -----
        tk.Label(wrap, text="Gemini API Keys", bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"], font=(None, 10, "bold")).pack(anchor="w")
        keys_frame = tk.Frame(wrap, bg=self.current_theme["bg_primary"]) 
        keys_frame.pack(fill=tk.BOTH, expand=True)
        listbox = tk.Listbox(keys_frame, height=6, bg=self.current_theme["bg_tertiary"], fg=self.current_theme["text_primary"], selectbackground=self.current_theme["accent_blue"], activestyle="none")
        listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, pady=(2, 6))

        def _mask(k: str) -> str:
            k = k or ""
            return ("*" * max(0, len(k) - 4)) + k[-4:]

        def _refresh_keys():
            listbox.delete(0, tk.END)
            for i, k in enumerate(self.api_keys or []):
                suffix = "  (active)" if i == self.active_key_index else ""
                listbox.insert(tk.END, f"{_mask(k)}{suffix}")

        btns = tk.Frame(keys_frame, bg=self.current_theme["bg_primary"]) 
        btns.pack(side=tk.LEFT, padx=(8,0), anchor="n")

        def _add_key():
            sub = tk.Toplevel(dialog)
            sub.title("Add API Key")
            sub.configure(bg=self.current_theme["bg_primary"]) 
            tk.Label(sub, text="Paste API Key:", bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"]).pack(anchor="w", padx=10, pady=(10,0))
            sv = tk.StringVar()
            ent = tk.Entry(sub, textvariable=sv, width=48, show="*", bg=self.current_theme["bg_tertiary"], fg=self.current_theme["text_primary"]) 
            ent.pack(padx=10, pady=6)
            def _ok():
                val = sv.get().strip()
                if val:
                    self.api_keys.append(val)
                    _refresh_keys()
                sub.destroy()
            tk.Button(sub, text="Add", command=_ok, bg=self.current_theme["accent_blue"], fg=self.current_theme["text_primary"], relief="flat").pack(pady=(0,10))
            sub.grab_set()

        def _edit_key():
            sel = listbox.curselection()
            if not sel:
                return
            idx = sel[0]
            sub = tk.Toplevel(dialog)
            sub.title("Edit API Key")
            sub.configure(bg=self.current_theme["bg_primary"]) 
            tk.Label(sub, text="Edit API Key:", bg=self.current_theme["bg_primary"], fg=self.current_theme["text_primary"]).pack(anchor="w", padx=10, pady=(10,0))
            sv = tk.StringVar(value=self.api_keys[idx])
            ent = tk.Entry(sub, textvariable=sv, width=48, show="*", bg=self.current_theme["bg_tertiary"], fg=self.current_theme["text_primary"]) 
            ent.pack(padx=10, pady=6)
            def _ok():
                self.api_keys[idx] = sv.get().strip()
                _refresh_keys()
                sub.destroy()
            tk.Button(sub, text="Save", command=_ok, bg=self.current_theme["accent_blue"], fg=self.current_theme["text_primary"], relief="flat").pack(pady=(0,10))
            sub.grab_set()

        def _remove_key():
            sel = listbox.curselection()
            if not sel:
                return
            idx = sel[0]
            del self.api_keys[idx]
            if self.active_key_index >= len(self.api_keys):
                self.active_key_index = max(0, len(self.api_keys) - 1)
            _refresh_keys()

        def _move(delta: int):
            sel = listbox.curselection()
            if not sel:
                return
            idx = sel[0]
            new = idx + delta
            if 0 <= new < len(self.api_keys):
                self.api_keys[idx], self.api_keys[new] = self.api_keys[new], self.api_keys[idx]
                if self.active_key_index == idx:
                    self.active_key_index = new
                elif self.active_key_index == new:
                    self.active_key_index = idx
                _refresh_keys()
                listbox.selection_clear(0, tk.END)
                listbox.selection_set(new)

        tk.Button(btns, text="Add", command=_add_key, bg=self.current_theme["accent_blue"], fg=self.current_theme["text_primary"], relief="flat", width=10).pack(pady=(2,4))
        tk.Button(btns, text="Edit", command=_edit_key, bg=self.current_theme["button_secondary"], fg=self.current_theme["text_primary"], relief="flat", width=10).pack(pady=4)
        tk.Button(btns, text="Remove", command=_remove_key, bg=self.current_theme["button_danger"], fg=self.current_theme["text_primary"], relief="flat", width=10).pack(pady=4)
        tk.Button(btns, text="Up", command=lambda: _move(-1), bg=self.current_theme["button_secondary"], fg=self.current_theme["text_primary"], relief="flat", width=10).pack(pady=4)
        tk.Button(btns, text="Down", command=lambda: _move(1), bg=self.current_theme["button_secondary"], fg=self.current_theme["text_primary"], relief="flat", width=10).pack(pady=4)

        # Auto refine
        auto_var = tk.BooleanVar(value=self.auto_refine)
        chk = tk.Checkbutton(
            wrap,
            text="Auto refine prompt before send",
            variable=auto_var,
            bg=self.current_theme["bg_primary"],
            fg=self.current_theme["text_primary"],
            selectcolor=self.current_theme["bg_primary"],
            activebackground=self.current_theme["bg_primary"],
            activeforeground=self.current_theme["text_primary"],
        )
        chk.pack(anchor="w", pady=(6, 6))

        # Footer buttons
        footer = tk.Frame(wrap, bg=self.current_theme["bg_primary"]) 
        footer.pack(fill=tk.X)

        def _save():
            # Persist chosen model
            self.model_name = model_var.get().strip() or self.model_name
            # Adjust active key if out-of-range
            if not self.api_keys:
                self.active_key_index = 0
            else:
                self.active_key_index = min(self.active_key_index, len(self.api_keys)-1)
            # Keep legacy field synced and reconfigure client
            self.api_key = (self.api_keys[self.active_key_index] if self.api_keys else None)
            self.auto_refine = auto_var.get()
            self._save_config()
            self._configure_gemini_client()
            dialog.destroy()

        tk.Button(footer, text="Save", command=_save, bg=self.current_theme["accent_blue"], fg=self.current_theme["text_primary"], relief="flat", width=12).pack(side=tk.RIGHT)

        _refresh_keys()
        dialog.grab_set()

    # ---------- Gemini client/config helpers ----------
    def _configure_gemini_client(self) -> None:
        if self.api_keys and 0 <= self.active_key_index < len(self.api_keys):
            key = self.api_keys[self.active_key_index]
        else:
            key = self.api_key
        if key:
            try:
                self.client = genai.Client(api_key=key)
            except Exception:
                self.client = None
        else:
            self.client = None

    def _is_rate_limit_error(self, err: Exception) -> bool:
        msg = str(err).lower()
        return ("429" in msg) or ("rate limit" in msg) or ("quota" in msg) or ("resource" in msg and "exhaust" in msg)

    def _rotate_api_key(self) -> bool:
        if not self.api_keys:
            return False
        start = self.active_key_index
        self.active_key_index = (self.active_key_index + 1) % len(self.api_keys)
        self.api_key = self.api_keys[self.active_key_index]
        self._configure_gemini_client()
        return self.active_key_index != start

    def _with_key_failover(self, func):
        tries = max(1, len(self.api_keys))
        last_err = None
        for _ in range(tries):
            try:
                return func()
            except Exception as e:
                last_err = e
                if self._is_rate_limit_error(e) and self._rotate_api_key():
                    continue
                raise
        if last_err:
            raise last_err


# ---------------------------------------------------------------------- entry-point

def main() -> None:
    if platform.system() == 'Windows':
        root = TkinterDnD.Tk()
    else:
        root = tk.Tk()

    app = InputPopup(root)
    root.protocol("WM_DELETE_WINDOW", lambda: (app.cleanup(), root.destroy()))
    root.mainloop()


if __name__ == "__main__":
    main()