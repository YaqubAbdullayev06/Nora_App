#!/usr/bin/env python3
"""
NoraApp — Comprehensive PDF Report Generator
Generates a detailed report covering architecture, features, UI/UX, AI, backend, and tech stack.
"""

from fpdf import FPDF
import os
from datetime import datetime


class NoraReport(FPDF):
    def __init__(self):
        super().__init__()
        self.set_auto_page_break(auto=True, margin=20)

    def header(self):
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, "NoraApp - Project Report", align="L")
        self.cell(0, 8, datetime.now().strftime("%d %B %Y"), align="R", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(0, 200, 150)
        self.set_line_width(0.5)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(6)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="C")

    def section_title(self, title, level=1):
        if level == 1:
            self.set_font("Helvetica", "B", 18)
            self.set_text_color(0, 180, 130)
            self.ln(4)
            self.cell(0, 12, title, new_x="LMARGIN", new_y="NEXT")
            self.set_draw_color(0, 200, 150)
            self.set_line_width(0.8)
            self.line(10, self.get_y(), 200, self.get_y())
            self.ln(6)
        elif level == 2:
            self.set_font("Helvetica", "B", 14)
            self.set_text_color(0, 140, 100)
            self.ln(3)
            self.cell(0, 10, title, new_x="LMARGIN", new_y="NEXT")
            self.ln(3)
        elif level == 3:
            self.set_font("Helvetica", "B", 11)
            self.set_text_color(60, 60, 60)
            self.ln(2)
            self.cell(0, 8, title, new_x="LMARGIN", new_y="NEXT")
            self.ln(2)

    def body_text(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_text_color(50, 50, 50)
        self.multi_cell(0, 5.5, text)
        self.ln(2)

    def bullet(self, text, indent=15):
        self.set_font("Helvetica", "", 10)
        self.set_text_color(50, 50, 50)
        x = self.get_x()
        self.set_x(x + indent)
        self.cell(5, 5.5, "-")
        self.multi_cell(0, 5.5, f" {text}")
        self.ln(1)

    def key_value(self, key, value, indent=15):
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(50, 50, 50)
        x = self.get_x()
        self.set_x(x + indent)
        kw = self.get_string_width(f"{key}: ") + 2
        self.cell(kw, 5.5, f"{key}: ")
        self.set_font("Helvetica", "", 10)
        self.multi_cell(0, 5.5, value)
        self.ln(1)

    def code_block(self, text):
        self.set_font("Courier", "", 9)
        self.set_text_color(40, 40, 40)
        self.set_fill_color(240, 240, 240)
        self.set_draw_color(200, 200, 200)
        x = self.get_x() + 10
        w = 180
        self.set_x(x)
        lines = text.strip().split("\n")
        h = len(lines) * 4.5 + 6
        if self.get_y() + h > 270:
            self.add_page()
        self.rect(x, self.get_y(), w, h, "DF")
        self.ln(3)
        for line in lines:
            self.set_x(x + 3)
            self.cell(w - 6, 4.5, line[:90], new_x="LMARGIN", new_y="NEXT")
        self.ln(5)

    def table_row(self, cells, widths, bold=False, fill=False):
        style = "B" if bold else ""
        self.set_font("Helvetica", style, 8)
        if fill:
            self.set_fill_color(230, 245, 240)
        self.set_text_color(50, 50, 50)
        self.set_draw_color(200, 200, 200)
        h = 6
        x_start = self.get_x()
        y_start = self.get_y()
        # Calculate max height needed
        max_lines = 1
        for cell_text, w in zip(cells, widths):
            lines = self.multi_cell(w - 2, h, cell_text, dry_run=True, output="LINES")
            if len(lines) > max_lines:
                max_lines = len(lines)
        row_h = max_lines * h
        # Draw cells
        x = x_start
        for cell_text, w in zip(cells, widths):
            self.set_xy(x, y_start)
            self.rect(x, y_start, w, row_h, "D")
            if fill:
                self.set_fill_color(230, 245, 240)
                self.rect(x, y_start, w, row_h, "F")
                self.rect(x, y_start, w, row_h, "D")
            self.set_xy(x + 1, y_start + 1)
            self.multi_cell(w - 2, h, cell_text)
            x += w
        self.set_xy(x_start, y_start + row_h)


def build_report():
    pdf = NoraReport()
    pdf.alias_nb_pages()
    pdf.set_margins(15, 15, 15)

    # ═══════════════════════════════════════════════════
    # COVER PAGE
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.ln(40)
    pdf.set_font("Helvetica", "B", 36)
    pdf.set_text_color(0, 180, 130)
    pdf.cell(0, 18, "NoraApp", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(6)
    pdf.set_font("Helvetica", "", 16)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(0, 10, "AI-Powered Focus & Productivity Platform", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(12)
    pdf.set_draw_color(0, 200, 150)
    pdf.set_line_width(1)
    pdf.line(60, pdf.get_y(), 150, pdf.get_y())
    pdf.ln(12)
    pdf.set_font("Helvetica", "", 11)
    pdf.set_text_color(80, 80, 80)
    pdf.cell(0, 8, "Comprehensive Project Report", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 8, "Architecture | Features | AI System | Backend | UI/UX Design", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(30)
    pdf.set_font("Helvetica", "I", 10)
    pdf.set_text_color(120, 120, 120)
    pdf.cell(0, 8, f"Generated: {datetime.now().strftime('%B %d, %Y')}", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 8, "Version 1.0", align="C", new_x="LMARGIN", new_y="NEXT")

    # ═══════════════════════════════════════════════════
    # TABLE OF CONTENTS
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("Table of Contents")
    toc = [
        ("1.", "Executive Summary"),
        ("2.", "Project Overview"),
        ("3.", "System Architecture"),
        ("4.", "Tech Stack"),
        ("5.", "Free Infrastructure Stack ($0/month)"),
        ("6.", "Adaptive Persona System (4 Age Groups)"),
        ("7.", "Feature Modules (15 Screens)"),
        ("8.", "AI System & Digital Assistant"),
        ("9.", "Backend API"),
        ("10.", "Services Layer (Flutter)"),
        ("11.", "UI/UX Design System"),
        ("12.", "Data Models"),
        ("13.", "Project File Structure"),
        ("14.", "How It Works End-to-End"),
        ("15.", "Business Model"),
        ("16.", "Future Roadmap"),
    ]
    for num, title in toc:
        pdf.set_font("Helvetica", "B", 11)
        pdf.set_text_color(0, 140, 100)
        pdf.cell(12, 7, num)
        pdf.set_font("Helvetica", "", 11)
        pdf.set_text_color(50, 50, 50)
        pdf.cell(0, 7, title, new_x="LMARGIN", new_y="NEXT")

    # ═══════════════════════════════════════════════════
    # 1. EXECUTIVE SUMMARY
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("1. Executive Summary")
    pdf.body_text(
        "NoraApp is an AI-powered focus and productivity mobile application designed to combat "
        "doomscrolling and social media addiction. It converts idle time into micro-learning and "
        "productive habits through an intelligent adaptive system."
    )
    pdf.body_text(
        "The app features a unique adaptive persona system with four age groups (Baby 1-6, Kid 6-12, "
        "Teen 12-18, Adult 18+), each receiving a personalized AI personality, UI theme, content "
        "strategy, and interaction style. Nora uses a Unified LLM Provider that auto-falls back "
        "across Groq API (fast, free), Ollama local, and Colab GPU (heavy models) for privacy-first "
        "AI inference. The backend runs on PocketBase (Oracle Cloud free tier) and Firebase Crashlytics "
        "for crash reporting -- all at zero cost."
    )
    pdf.body_text(
        "The architecture is a Flutter frontend communicating with a Python FastAPI backend. The backend "
        "integrates with a unified LLM provider (Groq + Ollama + Colab), SQLAlchemy for database "
        "persistence, and JWT for authentication. The frontend uses Provider for state management and "
        "platform channels for Android-native device integration."
    )
    pdf.section_title("Key Metrics", 2)
    pdf.key_value("Screens", "15 feature modules")
    pdf.key_value("Services", "6 Flutter services + 5 backend services")
    pdf.key_value("AI Providers", "Groq API (fast) + Ollama (local) + Colab GPU (heavy)")
    pdf.key_value("Backend Endpoints", "Auth, Chat, Command, App Classification, Health, AI Chat")
    pdf.key_value("Target Platforms", "Android (primary), iOS (planned)")
    pdf.key_value("Monthly Cost", "$0 -- no credit cards, no surprise bills")
    pdf.key_value("Design Philosophy", "Dark mode, minimalist, neptun green & purple neon accents")

    # ═══════════════════════════════════════════════════
    # 2. PROJECT OVERVIEW
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("2. Project Overview")
    pdf.section_title("Mission", 2)
    pdf.body_text(
        "Combat doomscrolling and social media addiction by converting idle time into micro-learning "
        "and productive habits. Nora is not just a timer or a blocker -- it is an intelligent companion "
        "that understands the user's age, habits, and goals, then adapts its behavior accordingly."
    )
    pdf.section_title("Target Audience", 2)
    pdf.bullet("ADHD users who need structured focus support")
    pdf.bullet("Students preparing for exams and managing study time")
    pdf.bullet("Freelancers and remote workers seeking productivity routines")
    pdf.bullet("Corporate employees managing digital wellness")
    pdf.bullet("Parents wanting age-appropriate screen time management for children")
    pdf.section_title("Core Value Proposition", 2)
    pdf.body_text(
        "Unlike generic screen time trackers, Nora provides: (1) Age-adaptive AI personalities that "
        "change language, complexity, and tone based on the user's age group; (2) Real device control "
        "via Android accessibility services for actual app blocking; (3) Privacy-first AI running "
        "locally via Ollama with no cloud dependency; (4) A complete productivity loop: plan -> "
        "focus -> reflect -> review."
    )

    # ═══════════════════════════════════════════════════
    # 3. SYSTEM ARCHITECTURE
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("3. System Architecture")
    pdf.body_text(
        "NoraApp follows a clean three-tier architecture: Presentation (Flutter/Dart), Business Logic "
        "(Services + Provider), and Data (FastAPI + SQLAlchemy + Unified LLM Provider). The frontend "
        "communicates with the backend via REST API over HTTP."
    )
    pdf.section_title("Architecture Diagram (Text)", 2)
    pdf.code_block(
        "+-------------------+       HTTP/REST       +-------------------+\n"
        "|   Flutter App     | <--------------------> |  FastAPI Backend   |\n"
        "|  (Presentation)   |                        |  (Business Logic)  |\n"
        "+-------------------+                        +-------------------+\n"
        "| - 15 Screens       |                        | - /auth (JWT)     |\n"
        "| - Provider State   |                        | - /ai/chat        |\n"
        "| - 6 Services       |                        | - /ai/command     |\n"
        "| - Platform Channels|                        | - /ai/health      |\n"
        "| - Design Tokens    |                        | - /ai/takeover    |\n"
        "+-------------------+                        +-------------------+\n"
        "         |                                            |\n"
        "   MethodChannel                              SQLAlchemy ORM\n"
        "   (Android Native)                                 |\n"
        "         |                                      +--------+\n"
        "  +-----------+                               | Unified |\n"
        "  | Android   |                               | LLM     |\n"
        "  | OS APIs   |                               | Provider|\n"
        "  | - Scanner |                               +--------+\n"
        "  | - Usage   |                               |  |  |  |\n"
        "  | - Focus   |                          Groq Oll Col CB\n"
        "  +-----------+                          API  Loc  GPU  d"
    )

    pdf.section_title("Communication Flow", 2)
    pdf.body_text(
        "1. User interacts with a Flutter screen (e.g., sends a chat message). 2. The screen calls a "
        "Flutter service (e.g., LlmService). 3. The service sends an HTTP request to the FastAPI "
        "backend. 4. The backend processes the request, optionally querying Ollama for LLM inference. "
        "5. The response flows back through the same chain. 6. For device operations (app scanning, "
        "blocking), Flutter uses MethodChannel to call Android native code directly."
    )

    # ═══════════════════════════════════════════════════
    # 4. TECH STACK
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("4. Tech Stack")
    pdf.section_title("Frontend (Flutter)", 2)
    pdf.key_value("Framework", "Flutter 3.x (Dart)")
    pdf.key_value("State Management", "Provider (ChangeNotifier pattern)")
    pdf.key_value("HTTP Client", "package:http (for REST API calls)")
    pdf.key_value("Platform Integration", "MethodChannel (Android native bridge)")
    pdf.key_value("SVG Rendering", "flutter_svg")
    pdf.key_value("Local Storage", "SharedPreferences + SQLite")
    pdf.key_value("Animations", "Lottie + Custom AnimationController")
    pdf.key_value("Typography", "SF Pro Display + Inter (custom fonts)")
    pdf.key_value("Design System", "Custom DesignTokens + PersonaTheme")

    pdf.section_title("Backend (Python)", 2)
    pdf.key_value("Framework", "FastAPI 0.104.1")
    pdf.key_value("ASGI Server", "Uvicorn 0.24.0")
    pdf.key_value("ORM", "SQLAlchemy 2.0.23")
    pdf.key_value("Database", "SQLite (dev) / MariaDB / PocketBase (prod)")
    pdf.key_value("Authentication", "JWT (python-jose) + bcrypt password hashing")
    pdf.key_value("AI/LLM", "Unified LLM Provider: Groq API + Ollama + Colab GPU")
    pdf.key_value("Validation", "Pydantic 2.5.2")
    pdf.key_value("HTTP Client", "httpx 0.25.2 (for Groq + Ollama communication)")
    pdf.key_value("Crash Reporting", "Firebase Crashlytics (unlimited, $0)")

    pdf.section_title("Android Native", 2)
    pdf.key_value("Language", "Kotlin (via Flutter MethodChannel)")
    pdf.key_value("App Scanning", "PackageManager API")
    pdf.key_value("Usage Tracking", "UsageStatsManager API")
    pdf.key_value("App Blocking", "AccessibilityService + DevicePolicyManager")
    pdf.key_value("Permissions", "Usage Access, Accessibility, Query All Packages")

    # ═══════════════════════════════════════════════════
    # 5. FREE INFRASTRUCTURE STACK
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("5. Free Infrastructure Stack ($0/month)")
    pdf.body_text(
        "NoraApp runs on a complete zero-cost infrastructure stack. No credit cards are required "
        "for any component. There are no surprise bills, no vendor lock-in, and no risk of "
        "unexpected charges. All services use free tiers that are permanently free, not trial periods."
    )

    pdf.section_title("LLM Inference Providers", 2)
    providers = [
        ("Groq API", "Fast LLM inference", "30 RPM, 14400 RPD", "No", "Primary (fastest)"),
        ("Ollama Local", "Self-hosted LLM", "Unlimited", "No", "Fallback 1"),
        ("Colab GPU", "Heavy models via T4", "~12h/day", "No", "Fallback 2 (GPU)"),
    ]
    widths = [28, 35, 35, 15, 35]
    pdf.table_row(["Provider", "Type", "Free Limit", "CC?", "Role"], widths, bold=True, fill=True)
    for row in providers:
        pdf.table_row(row, widths)

    pdf.ln(4)
    pdf.section_title("Infrastructure Services", 2)
    infra = [
        ("PocketBase", "Oracle Cloud", "4 OCPUs, 24GB RAM", "No", "Backend/DB"),
        ("Crashlytics", "Firebase", "Unlimited events", "No", "Crash reporting"),
        ("MariaDB", "Self-hosted", "Unlimited", "No", "Primary DB"),
    ]
    pdf.table_row(["Service", "Provider", "Free Limit", "CC?", "Purpose"], widths, bold=True, fill=True)
    for row in infra:
        pdf.table_row(row, widths)

    pdf.ln(4)
    pdf.section_title("Unified LLM Provider", 2)
    pdf.body_text(
        "The UnifiedLLMProvider class in backend/ai/llm_provider.py automatically selects the best "
        "available LLM provider with automatic fallback:"
    )
    pdf.bullet("Priority 1: Groq API -- fastest response times (30 requests/minute free)")
    pdf.bullet("Priority 2: Ollama Local -- runs on localhost:11434 (unlimited)")
    pdf.bullet("Priority 3: Colab GPU -- connects via ngrok tunnel to T4 GPU (15GB VRAM)")
    pdf.body_text(
        "Set LLM_PROVIDER=auto in .env to enable automatic fallback. The provider tries Groq first, "
        "falls back to Ollama local, then to Colab GPU. All existing code that uses "
        "from ai.ollama_client import ollama continues to work unchanged."
    )

    pdf.section_title("Total Monthly Cost", 2)
    pdf.code_block(
        "Groq API .................. $0  (free tier, 30 RPM)\n"
        "Colab GPU (T4) ........... $0  (free when running)\n"
        "Ollama Local ............. $0  (runs on your machine)\n"
        "PocketBase (Oracle) ...... $0  (4 OCPUs, 24GB RAM forever)\n"
        "Firebase Crashlytics ..... $0  (unlimited events)\n"
        "----------------------------------------\n"
        "TOTAL .................... $0/month"
    )

    # ═══════════════════════════════════════════════════
    # 6. ADAPTIVE PERSONA SYSTEM
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("6. Adaptive Persona System")
    pdf.body_text(
        "Nora's defining feature is its adaptive persona system. Based on the user's age group, the "
        "entire app experience changes: AI personality, language complexity, UI colors, mascot, content "
        "strategy, and even the max number of daily tasks. The system is defined in the AgeGroup enum "
        "and exposed via PersonaTheme."
    )
    personas = [
        ("Baby (1-6)", "Warm, gentle", "Simple words, emojis", "Colors, shapes, numbers", "1", "Bright pastels"),
        ("Kid (6-12)", "Fun, encouraging", "Enthusiastic, simple", "Homework, trivia, stories", "2", "Vibrant, gamified"),
        ("Teen (12-18)", "Mentor-like, real", "Modern, no lectures", "Study, mental health", "3", "Sleek dark theme"),
        ("Adult (18+)", "Professional", "Concise, frameworks", "Deep work, GTD, habits", "3", "Dark minimalist"),
    ]
    widths = [22, 25, 30, 35, 12, 28]
    pdf.table_row(["Group", "Personality", "Language", "Topics", "Tasks", "UI Style"], widths, bold=True, fill=True)
    for row in personas:
        pdf.table_row(row, widths)

    pdf.ln(4)
    pdf.section_title("Persona Configuration per Age Group", 2)
    pdf.bullet("Baby: mascotName='Nora', mascotEmoji='star', primaryColor=neptun green, maxDailyTasks=1")
    pdf.bullet("Kid: mascotName='Nora', mascotEmoji='rocket', primaryColor=blue, maxDailyTasks=2")
    pdf.bullet("Teen: mascotName='Nora', mascotEmoji='bolt', primaryColor=purple, maxDailyTasks=3")
    pdf.bullet("Adult: mascotName='Nora', mascotEmoji='diamond', primaryColor=cyan, maxDailyTasks=3")
    pdf.body_text(
        "Each persona has a unique system prompt that controls the LLM's personality, vocabulary, "
        "response length, and topic focus. The prompt changes dynamically based on the age group, "
        "ensuring age-appropriate interactions at all times."
    )

    # ═══════════════════════════════════════════════════
    # 7. FEATURE MODULES
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("7. Feature Modules (15 Screens)")
    features = [
        ("Splash", "App loading screen with brand animation", "splash_screen.dart"),
        ("Welcome", "First-time user greeting and onboarding start", "welcome_screen.dart"),
        ("Onboarding", "Multi-step persona selection, permissions setup", "onboarding_screen.dart"),
        ("Auth", "Login/Register with JWT, age group selection", "auth_screen.dart"),
        ("Home", "Age-adaptive dashboard: header, insights, stats, actions, motivation", "home_screen.dart"),
        ("Chat", "AI chat with Nora using Ollama LLM, age-group personalities", "chat_screen.dart"),
        ("Assistant", "Digital assistant with device control (scan, block, track, focus)", "assistant_screen.dart"),
        ("Scan", "AI-powered app scanning with classification and blocking recommendations", "app_scan_screen.dart"),
        ("Timer", "Pomodoro-style focus timer with blocking integration", "timer_screen.dart"),
        ("Plan", "Daily planning: morning tasks, active day tracking, evening reflection", "plan_screen.dart"),
        ("Weekly Review", "Comprehensive weekly reflection: goals, mood, AI insights, visualization", "weekly_review_screen.dart"),
        ("Breathing", "Guided breathing exercises for stress relief and focus", "breathing_screen.dart"),
        ("Stats", "Usage statistics, streaks, achievements, analytics", "stats_screen.dart"),
        ("Profile", "User profile, settings, persona info, streaks", "profile_screen.dart"),
        ("Feed", "AI-curated learning content feed", "feed_screen.dart"),
    ]
    for name, desc, file in features:
        pdf.section_title(f"{name}", 3)
        pdf.key_value("Description", desc, indent=20)
        pdf.key_value("File", file, indent=20)
        pdf.ln(1)

    pdf.add_page()
    pdf.section_title("Feature: Home Screen", 2)
    pdf.body_text(
        "The Home screen is the main dashboard, composed of five widgets: HomeHeader (greeting, "
        "streak, persona mascot), HomeInsight (AI-generated smart summary of today's usage), "
        "HomeStats (focus minutes, tasks completed, streak), HomeActions (quick action buttons "
        "to start focus, scan apps, chat), and HomeMotivation (age-appropriate motivational quote)."
    )
    pdf.section_title("Feature: Chat Screen", 2)
    pdf.body_text(
        "Full chat interface for talking to Nora AI. Uses LlmService to send messages to the backend, "
        "which forwards to Ollama. Maintains conversation history (last 10 messages for context). "
        "Shows backend connection status (Online/Offline). Persona-adaptive: different mascot emoji, "
        "greeting, and personality per age group."
    )
    pdf.section_title("Feature: Digital Assistant", 2)
    pdf.body_text(
        "A more advanced chat interface with real device control capabilities. The AI can execute "
        "JSON actions: scan_apps, block_apps, unblock_apps, start_focus, show_usage, show_recommendations. "
        "Includes quick action chips for common operations. Builds device context (blocked apps, "
        "usage data, scan results) and sends it with each command for context-aware AI responses."
    )
    pdf.section_title("Feature: App Scanner", 2)
    pdf.body_text(
        "Tabbed interface (All Apps / AI Recommend / Blocked) for managing device applications. "
        "Scans all installed apps via Android MethodChannel, merges usage data, sends to backend "
        "AI classifier for categorization, then displays results with real app icons loaded in "
        "parallel batches. Users can toggle block status per-app or apply all AI recommendations."
    )
    pdf.section_title("Feature: Daily Plan", 2)
    pdf.body_text(
        "Four-state adaptive flow: (1) Morning Planning -- user adds 1-3 tasks with priorities "
        "(Must do / Should do / Nice to do); (2) Active Day -- progress ring, task completion "
        "tracking, points earned; (3) Evening Reflection -- day summary with stats, journaling "
        "prompt; (4) History View -- past plans with completion rates and reflection status."
    )
    pdf.section_title("Feature: Weekly Review", 2)
    pdf.body_text(
        "Comprehensive weekly reflection with animated entrance. Sections: WeeklySummaryCard (total "
        "focus, sessions, points, streak, days active), MoodSelector (emoji mood picker), GoalsSection "
        "(add/track weekly goals with progress bars), ReflectionsSection (age-adaptive prompts), "
        "AiInsightCard (generated insights), WeekVisualization (bar chart of daily focus minutes). "
        "All content adapts labels and complexity per age group."
    )

    # ═══════════════════════════════════════════════════
    # 8. AI SYSTEM
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("8. AI System & Digital Assistant")
    pdf.body_text(
        "Nora's AI system is the core intelligence layer. It operates in two modes: Chat Mode "
        "(conversational AI for Q&A and guidance) and Command Mode (digital assistant with device "
        "control capabilities). Both modes use age-group-specific system prompts."
    )
    pdf.section_title("Chat Mode (LlmService.sendMessage)", 2)
    pdf.body_text(
        "Sends user messages to /ai/chat endpoint. Backend constructs a system prompt based on "
        "age group (baby/kid/teen/adult), appends conversation history, and forwards to Ollama. "
        "Returns the AI response text. Used in ChatScreen."
    )
    pdf.section_title("Command Mode (LlmService.sendCommand)", 2)
    pdf.body_text(
        "Sends commands to /ai/command endpoint with device context (scan results, blocked apps, "
        "usage data). Backend uses assistant-specific prompts that include device control instructions. "
        "The AI can return JSON actions that are parsed and executed by the frontend."
    )
    pdf.section_title("AI Actions (JSON Protocol)", 2)
    actions = [
        ("scan_apps", "Triggers app scanning via MethodChannel"),
        ("block_apps", "Blocks specified packages (requires confirmation)"),
        ("unblock_apps", "Unblocks specified packages"),
        ("start_focus", "Starts a focus session with specified duration (minutes)"),
        ("show_usage", "Displays today's usage statistics"),
        ("show_recommendations", "Shows AI blocking recommendations"),
        ("analyze_usage", "Analyzes usage patterns for insights"),
    ]
    for action, desc in actions:
        pdf.key_value(action, desc, indent=20)

    pdf.section_title("Unified LLM Provider Integration", 2)
    pdf.body_text(
        "The backend communicates with multiple LLM providers via the UnifiedLLMProvider class. "
        "It automatically selects the best available provider: Groq API (fastest, free tier), "
        "Ollama local (localhost:11434), or Colab GPU (via ngrok tunnel). The system sends chat "
        "completion requests with age-group system prompts and user messages. The LLM processes "
        "the request and returns a response. All providers are free with no credit card required."
    )
    pdf.section_title("App Classification AI", 2)
    pdf.body_text(
        "When apps are scanned, the backend uses AI to classify them into categories (social_media, "
        "entertainment, games, productivity, messaging, education, finance, health, etc.). It also "
        "generates blocking recommendations based on the user's age group. For example, a Teen user "
        "might get social media apps recommended for blocking during study time."
    )

    # ═══════════════════════════════════════════════════
    # 9. BACKEND API
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("9. Backend API (FastAPI)")
    pdf.body_text(
        "The backend is a Python FastAPI application with SQLAlchemy ORM, JWT authentication, "
        "and Ollama LLM integration. It runs on Uvicorn and supports SQLite (development) or "
        "PostgreSQL (production)."
    )
    pdf.section_title("API Endpoints", 2)
    endpoints = [
        ("POST /auth/register", "Register new user (email, password, age_group)"),
        ("POST /auth/login", "Login with email/password, returns JWT token"),
        ("GET /auth/me", "Get current user profile (requires JWT)"),
        ("POST /ai/chat", "Send chat message to Nora AI (message, age_group, history)"),
        ("POST /ai/command", "Send command to digital assistant (command, age_group, context)"),
        ("GET /ai/health", "Check if Ollama backend is running"),
        ("POST /ai/classify", "Classify apps by category and generate blocking recommendations"),
    ]
    for endpoint, desc in endpoints:
        pdf.key_value(endpoint, desc, indent=10)

    pdf.section_title("Database Schema", 2)
    pdf.body_text(
        "The backend uses SQLAlchemy ORM with the following core models: User (id, email, "
        "hashed_password, age_group, persona_name, streak_days, total_points, created_at), "
        "TimerSession (id, user_id, duration_minutes, completed, blocked_apps_json, created_at), "
        "ContentItem (id, title, body, category, difficulty, age_group, created_at), "
        "Achievement (id, user_id, type, title, description, points, unlocked_at)."
    )
    pdf.section_title("Authentication Flow", 2)
    pdf.body_text(
        "1. User sends POST /auth/register with email, password, age_group. 2. Backend hashes "
        "password with bcrypt, stores user in database. 3. User sends POST /auth/login with "
        "credentials. 4. Backend verifies password, generates JWT token (python-jose) with user "
        "ID and expiry. 5. Flutter stores token in SharedPreferences. 6. All subsequent API "
        "calls include Authorization: Bearer <token> header."
    )

    # ═══════════════════════════════════════════════════
    # 10. SERVICES LAYER
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("10. Services Layer (Flutter)")
    services = [
        ("LlmService", "Connects to backend /ai/chat and /ai/command endpoints. Sends messages, "
         "receives responses, checks Ollama availability. Handles both chat and command modes."),
        ("AppScannerService", "Android MethodChannel bridge for scanning all installed apps, "
         "getting app details, managing blocked apps list, and retrieving app icons as base64."),
        ("FocusProtectionService", "Android MethodChannel bridge for focus mode protection. "
         "Manages authorization, blocking enable/disable, app selection, and status monitoring."),
        ("UsageTrackerService", "Tracks screen time per app, provides daily/weekly usage summaries, "
         "categorizes usage by app type (social, entertainment, productivity)."),
        ("ApiService", "General HTTP API client for backend communication. Handles auth tokens, "
         "app classification requests, and other API operations."),
        ("ProactiveAssistService", "Provides proactive AI-powered insights. Generates smart "
         "summaries of today's usage, suggests actions, and provides motivational content."),
    ]
    for name, desc in services:
        pdf.section_title(name, 3)
        pdf.body_text(desc)

    # ═══════════════════════════════════════════════════
    # 11. UI/UX DESIGN SYSTEM
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("11. UI/UX Design System")
    pdf.section_title("Design Philosophy", 2)
    pdf.body_text(
        "NoraApp follows Apple Human Interface Guidelines with a dark-mode-first approach. "
        "The visual identity is built around neptun green (#00C896) and purple neon accents, "
        "creating a modern, calming, and focused aesthetic. Every element is designed to reduce "
        "visual noise and support concentration."
    )
    pdf.section_title("Design Tokens (design_tokens.dart)", 2)
    tokens = [
        ("Background", "#0A0E1A (deep dark)"),
        ("Surface", "#141927 (card background)"),
        ("Surface Raised", "#1C2235 (elevated elements)"),
        ("Accent Primary", "#00C896 (neptun green)"),
        ("Accent Secondary", "#7B61FF (purple neon)"),
        ("Accent Tertiary", "#FF6B9D (pink accent)"),
        ("Text Primary", "#FFFFFF"),
        ("Text Secondary", "#B0B8C8"),
        ("Text Muted", "#6B7280"),
        ("Success", "#00C896"),
        ("Warning", "#FFB800"),
        ("Danger", "#FF4757"),
        ("Font Family Primary", "Inter"),
        ("Font Family Display", "SF Pro Display"),
    ]
    for name, value in tokens:
        pdf.key_value(name, value, indent=20)

    pdf.section_title("Persona-Based Theming", 2)
    pdf.body_text(
        "PersonaTheme generates complete theme configurations per age group. Each persona defines "
        "primary/secondary/tertiary colors, mascot name and emoji, greeting messages, plan titles, "
        "reflection prompts, and max daily tasks. The theme is applied app-wide via Provider."
    )
    pdf.section_title("Shared Components (NoraComponents)", 2)
    components = [
        "NoraButton -- Gradient primary button with icon, loading state, expansion",
        "NoraCard -- Themed card with optional gradient, border, padding",
        "NoraMascot -- Animated mascot display with glow effect",
        "SectionHeader -- Section title with icon and label",
        "PlanPromptCard -- Onboarding plan prompt with mascot illustration",
        "PlanTaskCard -- Task card with checkbox, priority, completion animation",
        "PlanProgressRing -- Circular progress indicator for task completion",
    ]
    for comp in components:
        pdf.bullet(comp)

    # ═══════════════════════════════════════════════════
    # 12. DATA MODELS
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("12. Data Models")
    models = [
        ("User", "id, email, name, ageGroup, personaName, streakDays, totalPoints, createdAt, lastActiveAt"),
        ("TimerSession", "id, userId, durationMinutes, completed, blockedAppsJson, createdAt"),
        ("ContentItem", "id, title, body, category, difficulty, ageGroup, createdAt"),
        ("Achievement", "id, userId, type, title, description, points, unlockedAt"),
        ("AppInfo", "packageName, appName, category, isSystemApp, isBlocked, aiRecommendedBlock, usageTodayMinutes"),
        ("DailyPlan", "date, tasks(List), allCompleted, pointsEarned, eveningReflected"),
        ("WeeklyReview", "weekStart, totalFocusMinutes, totalSessions, totalPointsEarned, streakDays, mood, goals, reflections, aiInsight"),
        ("ChatMessage", "role (user/assistant), content"),
        ("LlmResponse", "response, model, error"),
        ("AssistantResponse", "response, model, actions(List<AIAction>), error"),
        ("AIAction", "type, description, data(Map)"),
        ("FocusProtectionStatus", "supported, authorized, usageAccessGranted, accessibilityGranted, blockingEnabled, blockedApps, message"),
        ("UsageStatsSummary", "totalScreenTimeMinutes, socialMediaMinutes, entertainmentMinutes, productivityMinutes, appCount, topApps"),
    ]
    for name, fields in models:
        pdf.section_title(name, 3)
        pdf.body_text(fields)

    # ═══════════════════════════════════════════════════
    # 13. PROJECT FILE STRUCTURE
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("13. Project File Structure")
    pdf.code_block(
        "NoraApp/\n"
        "  lib/\n"
        "    main.dart                          # App entry, routes, providers\n"
        "    core/\n"
        "      constants/design_tokens.dart    # UI design tokens\n"
        "      enums/age_group.dart            # 4 age groups + persona mapping\n"
        "      theme/\n"
        "        app_theme.dart                # Light/Dark theme\n"
        "        persona_theme.dart            # Persona-based themes\n"
        "    models/\n"
        "      models.dart                     # User, TimerSession, ContentItem, Achievement\n"
        "      app_info.dart                   # AppInfo model\n"
        "    providers/\n"
        "      app_provider.dart               # Central state (persona, auth, timer, etc.)\n"
        "    services/\n"
        "      api_service.dart                # HTTP API client\n"
        "      llm_service.dart                # LLM integration (chat + command)\n"
        "      app_scanner_service.dart        # Android app scanning bridge\n"
        "      focus_protection_service.dart   # Focus mode protection bridge\n"
        "      usage_tracker_service.dart      # Screen time tracking\n"
        "      proactive_assist_service.dart   # AI-powered insights\n"
        "    features/\n"
        "      home/screens/home_screen.dart\n"
        "      chat/screens/chat_screen.dart\n"
        "      chat/screens/assistant_screen.dart\n"
        "      scan/screens/app_scan_screen.dart\n"
        "      plan/screens/plan_screen.dart\n"
        "      weekly_review/screens/weekly_review_screen.dart\n"
        "      timer/, auth/, onboarding/, breathing/,\n"
        "      stats/, profile/, feed/, splash/, welcome/\n"
        "    widgets/\n"
        "      nora_components.dart            # Shared UI components\n"
        "  backend/\n"
        "    main.py                           # FastAPI entry point\n"
        "    .env                              # GROQ_API_KEY, LLM_PROVIDER\n"
        "    ai/\n"
        "      llm_provider.py                 # Unified Groq/Ollama/Colab provider\n"
        "      ollama_client.py                # Backward-compatible wrapper\n"
        "      prompts.py                      # Age-group system prompts\n"
        "    api/                              # Route handlers\n"
        "    services/\n"
        "      agent_capabilities.py           # AI agent capabilities\n"
        "      app_classifier.py               # App classification logic\n"
        "    models/                           # SQLAlchemy ORM models\n"
        "    utils/                            # Utility functions\n"
        "    requirements.txt                  # Python dependencies\n"
        "  free-stack/\n"
        "    README.md                         # Full documentation\n"
        "    QUICKSTART.md                     # 5-minute setup guide\n"
        "    groq/                             # Standalone Groq scripts\n"
        "    colab-gpu/                        # Colab notebook + client\n"
        "    pocketbase/                       # Oracle Cloud setup\n"
        "    crashlytics/                      # Firebase integration\n"
        "    config/providers.json             # Provider registry"
    )

    # ═══════════════════════════════════════════════════
    # 14. HOW IT WORKS END-TO-END
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("14. How It Works End-to-End")
    pdf.section_title("User Journey", 2)
    steps = [
        "1. Install & Open: User installs NoraApp, sees splash screen with brand animation.",
        "2. Onboarding: Selects age group, grants permissions (Usage Access, Accessibility).",
        "3. Registration: Creates account or logs in (JWT authentication).",
        "4. Home Dashboard: Sees personalized dashboard with stats, quick actions, motivation.",
        "5. App Scanning: Scans all installed apps, AI classifies and recommends blocks.",
        "6. Focus Session: Starts timer, blocking apps are activated via accessibility service.",
        "7. AI Chat: Talks to Nora for guidance, study tips, or just conversation.",
        "8. Digital Assistant: Uses voice-like commands to scan, block, track, and focus.",
        "9. Daily Planning: Sets morning tasks, tracks completion, reflects in evening.",
        "10. Weekly Review: Reviews weekly progress, sets goals, gets AI insights.",
    ]
    for step in steps:
        pdf.bullet(step)

    pdf.section_title("Focus Session Flow", 2)
    pdf.code_block(
        "User taps 'Start Focus' -> Timer starts -> FocusProtectionService.enableBlocking()\n"
        "-> MethodChannel calls Android AccessibilityService\n"
        "-> Blocked apps trigger overlay when opened\n"
        "-> Timer completes -> Stats updated -> Points earned\n"
        "-> Streak checked -> Achievements potentially unlocked"
    )

    pdf.section_title("AI Chat Flow", 2)
    pdf.code_block(
        "User types message -> LlmService.sendMessage()\n"
        "-> HTTP POST to backend /ai/chat\n"
        "-> Backend constructs prompt (age-group system + history)\n"
        "-> Forwards to Ollama LLM (local inference)\n"
        "-> Response returned to Flutter -> Displayed in chat UI"
    )

    # ═══════════════════════════════════════════════════
    # 15. BUSINESS MODEL
    # ═══════════════════════════════════════════════════
    pdf.add_page()
    pdf.section_title("15. Business Model")
    pdf.section_title("B2C Freemium", 2)
    pdf.bullet("Free Tier: Basic timer, manual app blocking, limited AI chat (5 messages/day)")
    pdf.bullet("Premium ($4.99/mo): Unlimited AI chat, smart blocking, weekly reports, custom themes")
    pdf.bullet("Family ($9.99/mo): Up to 5 family members, parental controls, child personas")
    pdf.section_title("B2B (Companies/Universities)", 2)
    pdf.bullet("Enterprise Dashboard: Team productivity analytics, anonymized aggregate data")
    pdf.bullet("Per-seat pricing: $2.99/user/month for corporate wellness programs")
    pdf.bullet("University licenses: Bulk pricing for student digital wellness initiatives")
    pdf.section_title("Revenue Projections", 2)
    pdf.body_text(
        "Year 1 target: 50K free users, 5K premium subscribers, 2 enterprise clients. "
        "Projected ARR: $300K-$500K. Break-even expected at 15K premium subscribers."
    )

    # ═══════════════════════════════════════════════════
    # 16. FUTURE ROADMAP
    # ═══════════════════════════════════════════════════
    pdf.section_title("16. Future Roadmap")
    roadmap = [
        ("Phase 1 (Current)", "Core app with AI chat, app scanning, focus timer, daily planning"),
        ("Phase 2 (Q4 2026)", "iOS support (Screen Time API), cloud sync, social features, achievement system"),
        ("Phase 3 (Q1 2027)", "Wearable integration (Apple Watch, Wear OS), calendar sync"),
        ("Phase 4 (Q2 2027)", "Enterprise dashboard, team analytics, API for third-party integrations"),
        ("Phase 5 (H2 2027)", "Voice assistant mode, AR overlays, predictive focus scheduling"),
    ]
    for phase, desc in roadmap:
        pdf.key_value(phase, desc, indent=10)

    pdf.ln(10)
    pdf.set_font("Helvetica", "I", 10)
    pdf.set_text_color(120, 120, 120)
    pdf.cell(0, 8, "End of Report", align="C", new_x="LMARGIN", new_y="NEXT")

    # Save
    output_path = os.path.join(os.path.dirname(__file__), "NoraApp_Report.pdf")
    pdf.output(output_path)
    print(f"Report generated: {output_path}")
    return output_path


if __name__ == "__main__":
    build_report()
