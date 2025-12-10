#!/bin/bash
# Prerequisites Installation Script (Linux)
# Installs all required tools and dependencies for Strix Halo QoS

set -e

SKIP_OLLAMA=false
SKIP_PYTHON=false
SKIP_BUILD_TOOLS=false
SKIP_MODELS=false
SKIP_OPTIONAL=false
INSTALL_OPTIONAL=false
START_OLLAMA=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-ollama)
            SKIP_OLLAMA=true
            shift
            ;;
        --skip-python)
            SKIP_PYTHON=true
            shift
            ;;
        --skip-build-tools)
            SKIP_BUILD_TOOLS=true
            shift
            ;;
        --skip-models)
            SKIP_MODELS=true
            shift
            ;;
        --skip-optional)
            SKIP_OPTIONAL=true
            shift
            ;;
        --install-optional)
            INSTALL_OPTIONAL=true
            shift
            ;;
        --start-ollama)
            START_OLLAMA=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

step() {
    echo -e "\n${CYAN}=== $1 ===${NC}"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if Ollama server is running
check_ollama_server() {
    if command -v ollama &> /dev/null; then
        # Try to list models - if server is running, this will succeed
        if ollama list &> /dev/null; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Check if running as root (for some installations)
NEED_ROOT=false

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt-get install -y"
    UPDATE_CMD="sudo apt-get update"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    INSTALL_CMD="sudo yum install -y"
    UPDATE_CMD="sudo yum check-update"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
    UPDATE_CMD="sudo dnf check-update"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    UPDATE_CMD="sudo pacman -Sy"
else
    PKG_MANAGER="unknown"
    warning "Unknown package manager. Some installations may need to be done manually."
fi

echo -e "${MAGENTA}=== Strix Halo QoS - Prerequisites Installation ===${NC}"
echo ""

# 1. Install Ollama
if [ "$SKIP_OLLAMA" = false ]; then
    step "Installing Ollama"
    
    if command -v ollama &> /dev/null; then
        VERSION=$(ollama --version 2>&1)
        success "Ollama already installed: $VERSION"
        
        # Check if server is running
        if check_ollama_server; then
            success "Ollama server is running"
        else
            warning "Ollama server is not running"
            if [ "$START_OLLAMA" = true ]; then
                echo "Starting Ollama server in background..."
                nohup ollama serve > /tmp/ollama.log 2>&1 &
                sleep 2
                if check_ollama_server; then
                    success "Ollama server started successfully"
                else
                    error "Failed to start Ollama server"
                    echo "  Try starting manually: ollama serve"
                fi
            else
                echo "  To start the server, run one of:"
                echo "    - ollama serve (foreground)"
                echo "    - sudo systemctl start ollama (systemd service)"
                echo "    - nohup ollama serve > /dev/null 2>&1 & (background)"
                echo "  Or use --start-ollama flag to start automatically"
            fi
        fi
    else
        warning "Ollama not found. Installing..."
        
        # Install Ollama
        curl -fsSL https://ollama.ai/install.sh | sh
        
        if command -v ollama &> /dev/null; then
            success "Ollama installed successfully"
            warning "Ollama server needs to be started before pulling models"
            echo "  Start with: ollama serve"
            echo "  Or as a service: sudo systemctl start ollama"
        else
            error "Ollama installation failed"
            warning "Please install manually: curl -fsSL https://ollama.ai/install.sh | sh"
        fi
    fi
fi

# 2. Install Python and Dependencies
if [ "$SKIP_PYTHON" = false ]; then
    step "Installing Python and Dependencies"
    
    # Check Python
    PYTHON_CMD=""
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        VERSION=$($PYTHON_CMD --version 2>&1)
        success "Python found: $VERSION"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
        VERSION=$($PYTHON_CMD --version 2>&1)
        success "Python found: $VERSION"
    else
        warning "Python not found. Installing..."
        NEED_ROOT=true
        
        if [ "$PKG_MANAGER" = "apt" ]; then
            $UPDATE_CMD
            $INSTALL_CMD python3 python3-pip python3-venv python3-full
        elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
            $INSTALL_CMD python3 python3-pip
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            $INSTALL_CMD python python-pip
        else
            error "Please install Python 3.8+ manually"
        fi
        
        if command -v python3 &> /dev/null; then
            PYTHON_CMD="python3"
            success "Python installed"
        else
            error "Python installation failed"
        fi
    fi
    
    # Install Python packages
    if [ -n "$PYTHON_CMD" ]; then
        echo "Installing Python packages..."
        
        # Check if we should use virtual environment
        VENV_PATH="$(dirname "$0")/../venv"
        USE_VENV=false
        
        # Try to create virtual environment
        if [ ! -d "$VENV_PATH" ]; then
            echo "Creating virtual environment..."
            if $PYTHON_CMD -m venv "$VENV_PATH" 2>/dev/null; then
                USE_VENV=true
                success "Virtual environment created at $VENV_PATH"
            else
                warning "Could not create virtual environment (python3-venv may be missing)"
                warning "Will try --user installation instead"
            fi
        else
            USE_VENV=true
            success "Using existing virtual environment"
        fi
        
        if [ "$USE_VENV" = true ]; then
            # Use virtual environment
            VENV_PYTHON="$VENV_PATH/bin/python"
            VENV_PIP="$VENV_PATH/bin/pip"
            
            # Upgrade pip
            $VENV_PIP install --upgrade pip
            
            # Install requirements
            REQUIREMENTS_FILE="$(dirname "$0")/../requirements.txt"
            if [ -f "$REQUIREMENTS_FILE" ]; then
                $VENV_PIP install -r "$REQUIREMENTS_FILE"
            else
                warning "requirements.txt not found, installing packages individually..."
                $VENV_PIP install psutil matplotlib seaborn
            fi
            
            success "Python packages installed in virtual environment"
            echo "  To activate: source venv/bin/activate"
        else
            # Try --user installation
            warning "Attempting --user installation (may require user site-packages)"
            
            # Upgrade pip
            $PYTHON_CMD -m pip install --upgrade pip --user 2>/dev/null || \
            $PYTHON_CMD -m pip install --upgrade pip --break-system-packages 2>/dev/null || \
            $PYTHON_CMD -m pip install --upgrade pip
            
            # Install requirements
            REQUIREMENTS_FILE="$(dirname "$0")/../requirements.txt"
            if [ -f "$REQUIREMENTS_FILE" ]; then
                $PYTHON_CMD -m pip install --user -r "$REQUIREMENTS_FILE" 2>/dev/null || \
                $PYTHON_CMD -m pip install --break-system-packages -r "$REQUIREMENTS_FILE" 2>/dev/null || \
                $PYTHON_CMD -m pip install -r "$REQUIREMENTS_FILE"
            else
                warning "requirements.txt not found, installing packages individually..."
                $PYTHON_CMD -m pip install --user psutil matplotlib seaborn 2>/dev/null || \
                $PYTHON_CMD -m pip install --break-system-packages psutil matplotlib seaborn 2>/dev/null || \
                $PYTHON_CMD -m pip install psutil matplotlib seaborn
            fi
            
            success "Python packages installed (--user mode)"
        fi
    fi
fi

# 3. Install Build Tools
if [ "$SKIP_BUILD_TOOLS" = false ]; then
    step "Installing Build Tools"
    
    # Check CMake
    if command -v cmake &> /dev/null; then
        VERSION=$(cmake --version | head -n 1)
        success "CMake found: $VERSION"
    else
        warning "CMake not found. Installing..."
        NEED_ROOT=true
        
        if [ "$PKG_MANAGER" = "apt" ]; then
            $UPDATE_CMD
            $INSTALL_CMD cmake
        elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
            $INSTALL_CMD cmake
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            $INSTALL_CMD cmake
        else
            error "Please install CMake manually"
        fi
        
        if command -v cmake &> /dev/null; then
            success "CMake installed"
        else
            error "CMake installation failed"
        fi
    fi
    
    # Check Compiler
    if command -v gcc &> /dev/null; then
        VERSION=$(gcc --version | head -n 1)
        success "GCC compiler found: $VERSION"
    else
        warning "GCC compiler not found. Installing build-essential..."
        NEED_ROOT=true
        
        if [ "$PKG_MANAGER" = "apt" ]; then
            $UPDATE_CMD
            $INSTALL_CMD build-essential
        elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
            $INSTALL_CMD gcc gcc-c++ make
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            $INSTALL_CMD base-devel
        else
            error "Please install build tools manually"
        fi
        
        if command -v gcc &> /dev/null; then
            success "GCC compiler installed"
        else
            error "Compiler installation failed"
        fi
    fi
fi

# 4. Install Essential Tools
step "Installing Essential Tools"

# Git (needed for cloning test projects)
if command -v git &> /dev/null; then
    VERSION=$(git --version 2>&1)
    success "Git found: $VERSION"
else
    warning "Git not found. Installing..."
    NEED_ROOT=true
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        $UPDATE_CMD
        $INSTALL_CMD git
    elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
        $INSTALL_CMD git
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        $INSTALL_CMD git
    fi
    
    if command -v git &> /dev/null; then
        success "Git installed"
    else
        error "Git installation failed"
    fi
fi

# FFmpeg (useful for audio/video processing)
if command -v ffmpeg &> /dev/null; then
    VERSION=$(ffmpeg -version 2>&1 | head -n 1)
    success "FFmpeg found: $VERSION"
else
    if [ "$INSTALL_OPTIONAL" = true ] || [ "$SKIP_OPTIONAL" = false ]; then
        warning "FFmpeg not found. Installing (useful for audio/video processing)..."
        NEED_ROOT=true
        
        if [ "$PKG_MANAGER" = "apt" ]; then
            $UPDATE_CMD
            $INSTALL_CMD ffmpeg
        elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
            $INSTALL_CMD ffmpeg
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            $INSTALL_CMD ffmpeg
        fi
        
        if command -v ffmpeg &> /dev/null; then
            success "FFmpeg installed"
        else
            warning "FFmpeg installation failed (optional)"
        fi
    else
        warning "FFmpeg: Not found (optional, useful for audio/video processing)"
    fi
fi

# 5. Install Optional Tools
if [ "$SKIP_OPTIONAL" = false ]; then
    step "Installing Optional Tools"
    
    # VS Code
    if command -v code &> /dev/null || command -v code-insiders &> /dev/null; then
        success "VS Code: Already installed"
    else
        if [ "$INSTALL_OPTIONAL" = true ]; then
            warning "VS Code: Not found. Installing..."
            
            if command -v snap &> /dev/null; then
                sudo snap install code --classic
                if command -v code &> /dev/null; then
                    success "VS Code installed via snap"
                else
                    warning "VS Code installation failed"
                fi
            elif [ "$PKG_MANAGER" = "apt" ]; then
                # Try installing via apt if snap not available
                $UPDATE_CMD
                if $INSTALL_CMD code 2>/dev/null; then
                    success "VS Code installed via apt"
                else
                    warning "VS Code: Install manually from https://code.visualstudio.com/"
                fi
            else
                warning "VS Code: Install manually from https://code.visualstudio.com/"
            fi
        else
            warning "VS Code: Not found (optional for Developer demo)"
            echo "  Install with: sudo snap install code --classic"
            echo "  Or use --install-optional flag to install automatically"
        fi
    fi
    
    # LibreOffice (for Office demo on Linux)
    if command -v libreoffice &> /dev/null; then
        VERSION=$(libreoffice --version 2>&1 | head -n 1)
        success "LibreOffice found: $VERSION"
    else
        if [ "$INSTALL_OPTIONAL" = true ]; then
            warning "LibreOffice: Not found. Installing..."
            NEED_ROOT=true
            
            if [ "$PKG_MANAGER" = "apt" ]; then
                $UPDATE_CMD
                $INSTALL_CMD libreoffice libreoffice-calc
            elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
                $INSTALL_CMD libreoffice libreoffice-calc
            elif [ "$PKG_MANAGER" = "pacman" ]; then
                $INSTALL_CMD libreoffice-fresh
            fi
            
            if command -v libreoffice &> /dev/null; then
                success "LibreOffice installed"
            else
                warning "LibreOffice installation failed (optional)"
            fi
        else
            warning "LibreOffice: Not found (optional for Office demo)"
            echo "  Install with: sudo apt-get install libreoffice-calc"
            echo "  Or use --install-optional flag to install automatically"
        fi
    fi
    
    # Performance tools (perf)
    if command -v perf &> /dev/null; then
        VERSION=$(perf --version 2>&1 | head -n 1)
        success "perf found: $VERSION"
    else
        if [ "$INSTALL_OPTIONAL" = true ]; then
            warning "perf: Not found. Installing..."
            NEED_ROOT=true
            
            if [ "$PKG_MANAGER" = "apt" ]; then
                $UPDATE_CMD
                KERNEL_VERSION=$(uname -r)
                if $INSTALL_CMD linux-tools-generic linux-tools-${KERNEL_VERSION} 2>/dev/null; then
                    success "perf installed"
                else
                    warning "perf installation failed (may need specific kernel version)"
                fi
            elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
                $INSTALL_CMD perf
                if command -v perf &> /dev/null; then
                    success "perf installed"
                else
                    warning "perf installation failed"
                fi
            elif [ "$PKG_MANAGER" = "pacman" ]; then
                $INSTALL_CMD perf
                if command -v perf &> /dev/null; then
                    success "perf installed"
                else
                    warning "perf installation failed"
                fi
            fi
        else
            warning "perf: Not found (optional for advanced metrics)"
            echo "  Install with: sudo apt-get install linux-tools-generic"
            echo "  Or use --install-optional flag to install automatically"
        fi
    fi
    
    # curl (should be installed, but check anyway)
    if command -v curl &> /dev/null; then
        success "curl: Already installed"
    else
        warning "curl: Not found. Installing..."
        NEED_ROOT=true
        
        if [ "$PKG_MANAGER" = "apt" ]; then
            $UPDATE_CMD
            $INSTALL_CMD curl
        elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
            $INSTALL_CMD curl
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            $INSTALL_CMD curl
        fi
        
        if command -v curl &> /dev/null; then
            success "curl installed"
        else
            error "curl installation failed (required for Ollama installation)"
        fi
    fi
fi

# 6. Install LLM Models
if [ "$SKIP_MODELS" = false ]; then
    step "Installing LLM Models"
    
    if command -v ollama &> /dev/null; then
        # Check if server is running before attempting to pull models
        if ! check_ollama_server; then
            warning "Ollama server is not running. Cannot pull models."
            if [ "$START_OLLAMA" = true ]; then
                echo "Starting Ollama server in background..."
                nohup ollama serve > /tmp/ollama.log 2>&1 &
                sleep 2
                if check_ollama_server; then
                    success "Ollama server started successfully"
                else
                    error "Failed to start Ollama server"
                    echo ""
                    echo "To start the Ollama server manually, choose one:"
                    echo "  1. Run in foreground: ollama serve"
                    echo "  2. Run as systemd service: sudo systemctl start ollama"
                    echo "  3. Run in background: nohup ollama serve > /dev/null 2>&1 &"
                    echo ""
                    echo "After starting the server, you can pull models manually:"
                    echo "  ollama pull codellama:7b"
                    exit 1
                fi
            else
                echo ""
                echo "To start the Ollama server, choose one:"
                echo "  1. Run in foreground: ollama serve"
                echo "  2. Run as systemd service: sudo systemctl start ollama"
                echo "  3. Run in background: nohup ollama serve > /dev/null 2>&1 &"
                echo "  4. Use --start-ollama flag to start automatically"
                echo ""
                echo "After starting the server, you can pull models manually:"
                echo "  ollama pull codellama:7b"
                echo ""
                echo "Or re-run this script with: ./scripts/install_prerequisites.sh --start-ollama"
            fi
        else
            echo "Pulling required models (this may take a while)..."
            echo ""
            
            MODELS=("codellama:7b")
            for model in "${MODELS[@]}"; do
                echo "Pulling $model..."
                if ollama pull "$model" 2>&1; then
                    success "$model installed"
                else
                    error "Failed to pull $model"
                    warning "Make sure Ollama server is running: ollama serve"
                fi
            done
        fi
    else
        warning "Ollama not found. Install Ollama first, then run:"
        echo "  ollama pull codellama:7b"
    fi
fi

# 7. Verify Installations
step "Verification"

ALL_GOOD=true

# Check Ollama
if command -v ollama &> /dev/null; then
    success "Ollama: OK"
else
    error "Ollama: Not found"
    ALL_GOOD=false
fi

# Check Python
if command -v python3 &> /dev/null; then
    success "Python: OK"
    
    # Check packages (try virtual environment first, then system)
    VENV_PATH="$(dirname "$0")/../venv"
    PYTHON_CHECK_CMD="python3"
    
    if [ -d "$VENV_PATH" ] && [ -f "$VENV_PATH/bin/python" ]; then
        PYTHON_CHECK_CMD="$VENV_PATH/bin/python"
        success "  Using virtual environment for package checks"
    fi
    
    PACKAGES=("psutil" "matplotlib" "seaborn")
    for pkg in "${PACKAGES[@]}"; do
        if $PYTHON_CHECK_CMD -c "import $pkg" 2>/dev/null; then
            success "  $pkg: OK"
        else
            error "  $pkg: Not installed"
            ALL_GOOD=false
        fi
    done
else
    error "Python: Not found"
    ALL_GOOD=false
fi

# Check CMake
if command -v cmake &> /dev/null; then
    success "CMake: OK"
else
    warning "CMake: Not found (optional for some demos)"
fi

# Check Compiler
if command -v gcc &> /dev/null; then
    success "GCC Compiler: OK"
else
    warning "Compiler: Not found (required for Developer demo)"
fi

# Summary
echo ""
echo -e "${MAGENTA}=== Installation Summary ===${NC}"

if [ "$ALL_GOOD" = true ]; then
    success "All critical prerequisites are installed!"
    echo ""
    
    # Check if virtual environment was created
    VENV_PATH="$(dirname "$0")/../venv"
    if [ -d "$VENV_PATH" ]; then
        echo "Note: Python packages are installed in a virtual environment"
        echo "  Activate it with: source venv/bin/activate"
        echo "  Or use: venv/bin/python for scripts"
        echo ""
    fi
    
    echo "Next steps:"
    echo "  1. Run verification: ./scripts/verify_setup.sh"
    echo "  2. Prepare demo assets:"
    echo "     - Clone test project: git clone https://github.com/microsoft/terminal.git test-projects/terminal"
    echo "     - Prepare video/audio files for Creator/Office demos (see README.md)"
    echo "  3. Run a demo: ./scripts/dev_qos_demo.sh --quick-test"
    echo ""
    echo "To install optional tools (VS Code, LibreOffice, perf), run:"
    echo "  ./scripts/install_prerequisites.sh --install-optional"
else
    warning "Some prerequisites are missing"
    echo "Please install missing components and run this script again"
    echo "Or run: ./scripts/verify_setup.sh to check status"
fi

if [ "$NEED_ROOT" = true ] && [ "$EUID" -ne 0 ]; then
    echo ""
    warning "Some installations require root privileges"
    echo "You may need to run parts of this script with sudo"
fi

echo ""

