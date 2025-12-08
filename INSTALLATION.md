# Installation Guide

This guide explains how to install all prerequisites for the Strix Halo Memory QoS Demonstration.

## Quick Installation (Recommended)

Run the automated installation script:

```bash
./scripts/install_prerequisites.sh
```

This script will:
- ✅ Install Ollama automatically
- ✅ Install Python 3.8+ and pip
- ✅ Install Python packages (psutil, matplotlib, seaborn)
- ✅ Install CMake and build-essential
- ✅ Pull required LLM model (codellama:7b)
- ✅ Verify all installations

**Note**: Some installations may require `sudo` privileges.

## Manual Installation

If you prefer to install manually or the automated script doesn't work:

### 1. Install Ollama

```bash
curl -fsSL https://ollama.ai/install.sh | sh
```

### 2. Install Python

```bash
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv
```

### 3. Install Python Packages

**Option A: Using virtual environment (recommended)**

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Option B: System-wide installation**

```bash
pip install -r requirements.txt
```

Or individually:
```bash
pip install psutil matplotlib seaborn
```

### 4. Install Build Tools

```bash
sudo apt-get update
sudo apt-get install build-essential cmake
```

### 5. Install LLM Model

```bash
ollama pull codellama:7b
```

### 6. Prepare Test Project

The demo uses `test-projects/json` by default. If it doesn't exist:

```bash
./scripts/prepare_test_project.sh json
```

Or manually:

```bash
mkdir -p test-projects
cd test-projects
git clone https://github.com/nlohmann/json.git
cd json
cmake -B build
```

## Running the Demo

After installation, run the demo:

```bash
# Run for 10 minutes (600 seconds)
./scripts/memory_qos_demo.sh --duration 600

# Visualize results
LATEST_CSV=$(ls -t logs/memory_qos_metrics_*.csv | head -1)
python3 scripts/visualize_memory_qos.py --metrics-file "$LATEST_CSV"
```

## Troubleshooting

### Installation Script Fails

1. **Check permissions**: Some installations require administrator/sudo privileges
2. **Check internet connection**: Downloads require internet access
3. **Check disk space**: Models are large (several GB)
4. **Manual installation**: Use manual steps if automated script fails

### Ollama Installation Issues

- Check if Ollama service is running: `systemctl status ollama`
- Start service if needed: `sudo systemctl start ollama`
- Restart terminal after installation

### Python Package Installation Issues

**Permission errors:**
```bash
# Use --user flag
pip install --user -r requirements.txt

# Or use virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Missing packages:**
- Ensure all packages from `requirements.txt` are installed
- Check virtual environment is activated if using venv
- Verify Python version is 3.8 or higher

### Model Download Issues

**Slow downloads:**
- Models are large (several GB each)
- Download speed depends on internet connection
- Be patient, downloads can take 10-30 minutes

**Failed downloads:**
- Check internet connection
- Try again: `ollama pull codellama:7b`
- Check available disk space

### Build Tools Issues

- May require `sudo` privileges
- Update package lists first: `sudo apt-get update`
- Ensure adequate disk space (several GB)

### Test Project Issues

**Project not found:**
- Run `./scripts/prepare_test_project.sh json` to set up the test project
- Or use `--project-path` to specify a different CMake project

**Build fails:**
- Ensure CMake is installed: `cmake --version`
- Check project has a CMakeLists.txt file
- Verify build directory permissions

## System Requirements

### Minimum Requirements

- **RAM**: 16GB (32GB recommended)
- **Disk Space**: 20GB free space (for models and test projects)
- **OS**: Linux (Ubuntu 22.04+ recommended)
- **Internet**: Required for downloads

### Recommended Requirements

- **RAM**: 32GB+
- **Disk Space**: 50GB+ free space
- **CPU**: Modern multi-core processor
- **GPU**: Optional, but helps with LLM inference

## Support

If you encounter issues:

1. Check [Troubleshooting Guide](docs/troubleshooting.md)
2. Review setup guide: [Linux Setup](env/linux_setup.md)
3. Contact Strix Halo team for assistance
