#!/bin/bash

# Pomodoro Timer - Advanced productivity timer for macOS terminal
# Author: José Meira
# Version: 1.0.0

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
VERSION="1.0.0"
CONFIG_DIR="$HOME/.pomodoro"
CONFIG_FILE="$CONFIG_DIR/config"
LOG_FILE="$CONFIG_DIR/pomodoro.log"
STATS_FILE="$CONFIG_DIR/stats.json"

# Default settings
DEFAULT_WORK_TIME=25
DEFAULT_SHORT_BREAK=5
DEFAULT_LONG_BREAK=15
DEFAULT_SESSIONS_UNTIL_LONG=4
DEFAULT_SOUND_ENABLED=true
DEFAULT_NOTIFICATIONS_ENABLED=true

# Current session variables
WORK_TIME=$DEFAULT_WORK_TIME
SHORT_BREAK=$DEFAULT_SHORT_BREAK
LONG_BREAK=$DEFAULT_LONG_BREAK
SESSIONS_UNTIL_LONG=$DEFAULT_SESSIONS_UNTIL_LONG
SOUND_ENABLED=$DEFAULT_SOUND_ENABLED
NOTIFICATIONS_ENABLED=$DEFAULT_NOTIFICATIONS_ENABLED

# Runtime variables
CURRENT_SESSION=1
TOTAL_SESSIONS_TODAY=0
PAUSED=false
START_TIME=""

# Create config directory if it doesn't exist
create_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        save_config
        init_stats
    fi
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# Save configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Pomodoro Timer Configuration
WORK_TIME=$WORK_TIME
SHORT_BREAK=$SHORT_BREAK
LONG_BREAK=$LONG_BREAK
SESSIONS_UNTIL_LONG=$SESSIONS_UNTIL_LONG
SOUND_ENABLED=$SOUND_ENABLED
NOTIFICATIONS_ENABLED=$NOTIFICATIONS_ENABLED
EOF
}

# Initialize stats file
init_stats() {
    if [ ! -f "$STATS_FILE" ]; then
        echo '{"daily_sessions": {}, "total_sessions": 0, "total_focus_time": 0}' > "$STATS_FILE"
    fi
}

# Show help
show_help() {
    cat << EOF
Pomodoro Timer v${VERSION}

DESCRIPTION:
    Advanced Pomodoro Technique timer for macOS with notifications, 
    statistics tracking, and customizable settings.

USAGE:
    pomodoro [OPTIONS] [COMMAND]

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    -w, --work-time MIN     Set work session duration (default: 25)
    -s, --short-break MIN   Set short break duration (default: 5)
    -l, --long-break MIN    Set long break duration (default: 15)
    -c, --cycles NUM        Sessions until long break (default: 4)
    --no-sound              Disable sound notifications
    --no-notifications      Disable system notifications
    --config                Show current configuration
    --reset-config          Reset to default configuration

COMMANDS:
    start                   Start a pomodoro session (default)
    stats                   Show productivity statistics
    reset-stats             Reset all statistics
    config                  Interactive configuration setup

EXAMPLES:
    pomodoro                        # Start with default settings
    pomodoro --work-time 30         # 30-minute work sessions
    pomodoro --no-sound             # Silent mode
    pomodoro stats                  # View statistics
    pomodoro config                 # Configure settings

KEYBOARD CONTROLS (during session):
    SPACE                   Pause/Resume timer
    q, Q                    Quit current session
    s, S                    Skip to break/next session
    r, R                    Reset current timer

NOTES:
    - Notifications require macOS notification permissions
    - Statistics are stored in ~/.pomodoro/
    - Config changes persist between sessions

EOF
}

# Show version
show_version() {
    echo "Pomodoro Timer v${VERSION}"
    echo "A productivity tool for the Pomodoro Technique"
}

# Show configuration
show_config() {
    echo -e "${CYAN}=== Current Configuration ===${NC}"
    echo -e "${BLUE}Work Time:${NC} ${WORK_TIME} minutes"
    echo -e "${BLUE}Short Break:${NC} ${SHORT_BREAK} minutes" 
    echo -e "${BLUE}Long Break:${NC} ${LONG_BREAK} minutes"
    echo -e "${BLUE}Sessions until Long Break:${NC} ${SESSIONS_UNTIL_LONG}"
    echo -e "${BLUE}Sound Notifications:${NC} $([ "$SOUND_ENABLED" = true ] && echo "Enabled" || echo "Disabled")"
    echo -e "${BLUE}System Notifications:${NC} $([ "$NOTIFICATIONS_ENABLED" = true ] && echo "Enabled" || echo "Disabled")"
    echo -e "${BLUE}Config File:${NC} $CONFIG_FILE"
    echo -e "${BLUE}Log File:${NC} $LOG_FILE"
}

# Interactive configuration
interactive_config() {
    echo -e "${CYAN}=== Pomodoro Configuration Setup ===${NC}"
    echo
    
    read -p "Work session duration (minutes) [$WORK_TIME]: " new_work
    WORK_TIME=${new_work:-$WORK_TIME}
    
    read -p "Short break duration (minutes) [$SHORT_BREAK]: " new_short
    SHORT_BREAK=${new_short:-$SHORT_BREAK}
    
    read -p "Long break duration (minutes) [$LONG_BREAK]: " new_long
    LONG_BREAK=${new_long:-$LONG_BREAK}
    
    read -p "Sessions until long break [$SESSIONS_UNTIL_LONG]: " new_cycles
    SESSIONS_UNTIL_LONG=${new_cycles:-$SESSIONS_UNTIL_LONG}
    
    read -p "Enable sound notifications? (y/N): " sound_choice
    SOUND_ENABLED=$([ "$sound_choice" = "y" ] || [ "$sound_choice" = "Y" ] && echo true || echo false)
    
    read -p "Enable system notifications? (y/N): " notif_choice
    NOTIFICATIONS_ENABLED=$([ "$notif_choice" = "y" ] || [ "$notif_choice" = "Y" ] && echo true || echo false)
    
    save_config
    echo -e "${GREEN}✅ Configuration saved!${NC}"
}

# Send system notification
send_notification() {
    local title="$1"
    local message="$2"
    local sound="$3"
    
    if [ "$NOTIFICATIONS_ENABLED" = true ]; then
        if [ "$SOUND_ENABLED" = true ] && [ -n "$sound" ]; then
            osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
        else
            osascript -e "display notification \"$message\" with title \"$title\""
        fi
    fi
}

# Play sound
play_sound() {
    if [ "$SOUND_ENABLED" = true ]; then
        # Use system sounds
        case $1 in
            "start") afplay /System/Library/Sounds/Ping.aiff 2>/dev/null || true ;;
            "break") afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true ;;
            "complete") afplay /System/Library/Sounds/Sosumi.aiff 2>/dev/null || true ;;
        esac
    fi
}

# Log session
log_session() {
    local session_type="$1"
    local duration="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $session_type session completed - ${duration} minutes" >> "$LOG_FILE"
}

# Update statistics
update_stats() {
    local session_type="$1"
    local duration="$2"
    local today=$(date '+%Y-%m-%d')
    
    # Simple stats update (would be more robust with jq in real implementation)
    if [ "$session_type" = "work" ]; then
        TOTAL_SESSIONS_TODAY=$((TOTAL_SESSIONS_TODAY + 1))
        # In a real implementation, update JSON stats file here
    fi
}

# Draw progress bar
draw_progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${BOLD}["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%% (%02d:%02d)${NC}" $percentage $((current / 60)) $((current % 60))
}

# Main timer function
run_timer() {
    local duration_minutes=$1
    local session_type="$2"
    local session_name="$3"
    
    local total_seconds=$((duration_minutes * 60))
    local remaining_seconds=$total_seconds
    
    # Clear screen and show header
    clear
    echo -e "${CYAN}🍅 Pomodoro Timer v${VERSION}${NC}"
    echo -e "${WHITE}${BOLD}$session_name${NC}"
    echo -e "${BLUE}Duration: ${duration_minutes} minutes${NC}"
    echo
    echo -e "${YELLOW}Controls: [SPACE] Pause/Resume | [Q] Quit | [S] Skip | [R] Reset${NC}"
    echo
    
    START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    while [ $remaining_seconds -gt 0 ]; do
        if [ "$PAUSED" = false ]; then
            # Update progress bar
            draw_progress_bar $((total_seconds - remaining_seconds)) $total_seconds
            
            # Check for keyboard input (non-blocking)
            if read -t 1 -n 1 key 2>/dev/null; then
                case $key in
                    ' ') # Space - pause/resume
                        PAUSED=true
                        echo -e "\n${YELLOW}⏸️  PAUSED - Press SPACE to resume${NC}"
                        continue
                        ;;
                    'q'|'Q') # Quit
                        echo -e "\n${RED}❌ Session cancelled${NC}"
                        return 1
                        ;;
                    's'|'S') # Skip
                        echo -e "\n${YELLOW}⏭️  Session skipped${NC}"
                        break
                        ;;
                    'r'|'R') # Reset
                        remaining_seconds=$total_seconds
                        echo -e "\n${BLUE}🔄 Timer reset${NC}"
                        continue
                        ;;
                esac
            fi
            
            remaining_seconds=$((remaining_seconds - 1))
        else
            # Paused state
            if read -t 1 -n 1 key 2>/dev/null; then
                case $key in
                    ' ') # Space - resume
                        PAUSED=false
                        echo -e "\r${GREEN}▶️  RESUMED                    ${NC}"
                        ;;
                    'q'|'Q') # Quit
                        echo -e "\n${RED}❌ Session cancelled${NC}"
                        return 1
                        ;;
                esac
            fi
        fi
    done
    
    # Session completed
    echo -e "\n${GREEN}✅ $session_name completed!${NC}"
    
    # Notifications and sounds
    send_notification "Pomodoro Timer" "$session_name completed!" "Glass"
    play_sound "complete"
    
    # Log and update stats
    log_session "$session_type" "$duration_minutes"
    update_stats "$session_type" "$duration_minutes"
    
    return 0
}

# Show statistics
show_stats() {
    echo -e "${CYAN}=== Productivity Statistics ===${NC}"
    echo
    echo -e "${BLUE}Today's Sessions:${NC} $TOTAL_SESSIONS_TODAY"
    echo -e "${BLUE}Current Cycle:${NC} Session $CURRENT_SESSION of $SESSIONS_UNTIL_LONG"
    echo
    
    if [ -f "$LOG_FILE" ]; then
        local today=$(date '+%Y-%m-%d')
        local today_sessions=$(grep "$today" "$LOG_FILE" | grep "work session" | wc -l | tr -d ' ')
        local today_focus_time=$((today_sessions * WORK_TIME))
        
        echo -e "${BLUE}Today's Completed Work Sessions:${NC} $today_sessions"
        echo -e "${BLUE}Today's Focus Time:${NC} $today_focus_time minutes"
        echo
        
        echo -e "${BLUE}Recent Sessions:${NC}"
        tail -10 "$LOG_FILE" 2>/dev/null | while read line; do
            echo -e "${PURPLE}  $line${NC}"
        done
    else
        echo -e "${YELLOW}No session history found${NC}"
    fi
}

# Reset statistics
reset_stats() {
    read -p "Are you sure you want to reset all statistics? (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        rm -f "$LOG_FILE" "$STATS_FILE"
        init_stats
        echo -e "${GREEN}✅ Statistics reset successfully${NC}"
    else
        echo -e "${YELLOW}Reset cancelled${NC}"
    fi
}

# Main pomodoro session manager
start_pomodoro() {
    echo -e "${CYAN}🍅 Starting Pomodoro Session ${CURRENT_SESSION}${NC}"
    echo
    
    # Work session
    if run_timer $WORK_TIME "work" "🎯 Work Session $CURRENT_SESSION"; then
        # Break time
        if [ $((CURRENT_SESSION % SESSIONS_UNTIL_LONG)) -eq 0 ]; then
            # Long break
            echo -e "${GREEN}Time for a long break! 🌟${NC}"
            sleep 2
            run_timer $LONG_BREAK "break" "☕ Long Break"
            CURRENT_SESSION=1
        else
            # Short break
            echo -e "${GREEN}Time for a short break! ☕${NC}"
            sleep 2
            run_timer $SHORT_BREAK "break" "🌱 Short Break"
            CURRENT_SESSION=$((CURRENT_SESSION + 1))
        fi
        
        # Ask if user wants to continue
        echo
        read -p "Start next session? (Y/n): " continue_session
        if [ "$continue_session" != "n" ] && [ "$continue_session" != "N" ]; then
            start_pomodoro
        fi
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -w|--work-time)
                WORK_TIME="$2"
                shift 2
                ;;
            -s|--short-break)
                SHORT_BREAK="$2"
                shift 2
                ;;
            -l|--long-break)
                LONG_BREAK="$2"
                shift 2
                ;;
            -c|--cycles)
                SESSIONS_UNTIL_LONG="$2"
                shift 2
                ;;
            --no-sound)
                SOUND_ENABLED=false
                shift
                ;;
            --no-notifications)
                NOTIFICATIONS_ENABLED=false
                shift
                ;;
            --config)
                show_config
                exit 0
                ;;
            --reset-config)
                rm -f "$CONFIG_FILE"
                echo -e "${GREEN}✅ Configuration reset to defaults${NC}"
                exit 0
                ;;
            start)
                # Default action, do nothing special
                shift
                ;;
            stats)
                show_stats
                exit 0
                ;;
            reset-stats)
                reset_stats
                exit 0
                ;;
            config)
                interactive_config
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}❌ This script requires macOS${NC}"
        exit 1
    fi
    
    # Setup
    create_config_dir
    load_config
    
    # Parse arguments
    parse_args "$@"
    
    # Default action: start pomodoro
    echo -e "${CYAN}🍅 Welcome to Pomodoro Timer v${VERSION}${NC}"
    echo
    show_config
    echo
    
    start_pomodoro
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}👋 Pomodoro session interrupted. See you next time!${NC}"; exit 0' INT

# Run main function
main "$@"
