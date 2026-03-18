#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  CAPS Dashboard – Mac Automation Setup
#  Run this ONCE to set up fully automatic daily updates
#  Usage: bash setup_automation.sh
# ═══════════════════════════════════════════════════════════════════

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.caps.dashboard"
PLIST_SRC="$SCRIPT_DIR/$PLIST_NAME.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
LOG_DIR="$SCRIPT_DIR/logs"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  CAPS Dashboard Automation Setup"
echo "═══════════════════════════════════════════════════"
echo ""

# ── Step 1: Create logs folder ───────────────────────────────────
mkdir -p "$LOG_DIR"
echo "✅ Log folder created: $LOG_DIR"

# ── Step 2: Install Python packages ──────────────────────────────
echo ""
echo "📦 Installing required Python packages..."
python3 -m pip install openpyxl requests gdown --quiet
echo "✅ Packages installed"

# ── Step 3: Check git is installed ───────────────────────────────
echo ""
if command -v git &> /dev/null; then
    echo "✅ Git found: $(git --version)"
else
    echo "⚠️  Git not found. Install from: https://git-scm.com/downloads"
    echo "   Git is needed for auto-push to GitHub/Vercel"
fi

# ── Step 4: Patch the plist with real paths ───────────────────────
echo ""
echo "🔧 Configuring scheduler with your folder path..."

# Replace placeholder paths in plist
sed "s|REPLACE_WITH_FULL_PATH|$SCRIPT_DIR|g" "$PLIST_SRC" > "$PLIST_DEST"
echo "✅ Scheduler config written to:"
echo "   $PLIST_DEST"

# ── Step 5: Register with launchd ────────────────────────────────
echo ""
echo "⏰ Registering 9 AM daily schedule..."

# Unload if already registered
launchctl unload "$PLIST_DEST" 2>/dev/null || true
# Load it
launchctl load "$PLIST_DEST"

# Verify it loaded
if launchctl list | grep -q "$PLIST_NAME"; then
    echo "✅ Scheduler registered successfully"
    echo "   Dashboard will auto-update every day at 9:00 AM"
else
    echo "⚠️  Scheduler may not have loaded. Try running:"
    echo "   launchctl load $PLIST_DEST"
fi

# ── Step 6: Set up Mac scheduled wake ────────────────────────────
echo ""
echo "⏰ Setting Mac to auto-wake at 8:55 AM daily..."
# Wake 5 min before script runs so Mac is ready
sudo pmset repeat wake MTWRFSU 08:55:00 2>/dev/null && \
    echo "✅ Mac will wake at 8:55 AM daily" || \
    echo "⚠️  Could not set wake time (needs sudo). Run manually:"
    echo "   sudo pmset repeat wake MTWRFSU 08:55:00"

# ── Step 7: Test run ─────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup complete! Running a test now..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
python3 "$SCRIPT_DIR/update_dashboard.py"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ ALL DONE — Automation is active"
echo ""
echo "  📅 Schedule:  Every day at 9:00 AM"
echo "  💻 Mac wake:  Every day at 8:55 AM"
echo "  📂 Logs:      $LOG_DIR"
echo ""
echo "  TO CHANGE TIME: Edit setup_automation.sh"
echo "    Change 08:55:00 (wake) and Hour=9 in plist"
echo "    Then run this script again"
echo ""
echo "  TO DISABLE:"
echo "    launchctl unload $PLIST_DEST"
echo ""
echo "  TO CHECK LAST RUN:"
echo "    cat $LOG_DIR/dashboard_run.log"
echo "═══════════════════════════════════════════════════"
