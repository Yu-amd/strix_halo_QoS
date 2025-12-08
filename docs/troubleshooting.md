# Troubleshooting Guide

Common issues and solutions for Strix Halo QoS.

## General Issues

### Scripts Won't Run

**Problem**: PowerShell scripts show execution policy errors.

**Solution**:
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set for current user (if allowed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Logs Directory Not Created

**Problem**: Scripts fail to create logs directory.

**Solution**:
```powershell
# Manually create logs directory
New-Item -ItemType Directory -Path logs -Force
```

### Path Issues

**Problem**: Scripts can't find files or directories.

**Solution**:
- Ensure you're running scripts from the repository root
- Use absolute paths if needed
- Check file paths use correct separators (`\` for Windows, `/` for Linux)

## Ollama Issues

### Ollama Not Found

**Problem**: `ollama: command not found` or `ollama is not recognized`.

**Solution**:
```powershell
# Windows: Check if Ollama is in PATH
$env:PATH -split ';' | Select-String ollama

# Add to PATH if needed (Windows)
# Or reinstall Ollama and ensure "Add to PATH" is checked
```

```bash
# Linux: Check installation
which ollama

# Reinstall if needed
curl -fsSL https://ollama.ai/install.sh | sh
```

### Ollama Service Not Running

**Problem**: Ollama commands hang or fail to connect.

**Solution**:
```powershell
# Windows: Check if Ollama is running
Get-Process ollama

# Start Ollama if not running
ollama serve
```

```bash
# Linux: Check service
systemctl status ollama

# Start service
sudo systemctl start ollama
```

### Model Not Available

**Problem**: Script reports model not found.

**Solution**:
```powershell
# List available models
ollama list

# Pull required models
ollama pull codellama:7b
ollama pull llama3:8b
```

### Model Download Fails

**Problem**: `ollama pull` fails or is very slow.

**Solution**:
- Check internet connection
- Try again (may be temporary network issue)
- Check available disk space
- Verify Ollama has write permissions

## Python Issues

### Python Not Found

**Problem**: `python: command not found`.

**Solution**:
```powershell
# Windows: Check Python installation
python --version

# Install if needed: winget install Python.Python.3.11
# Or download from python.org
```

```bash
# Linux: Install Python
sudo apt install python3 python3-pip
```

### Module Not Found

**Problem**: `ModuleNotFoundError: No module named 'whisper'`.

**Solution**:
```powershell
# Install required packages
pip install openai-whisper
pip install psutil
pip install requests

# Or install from requirements.txt
pip install -r requirements.txt
```

### Virtual Environment Issues

**Problem**: Packages installed but not found.

**Solution**:
```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # Linux
.\venv\Scripts\Activate.ps1  # Windows

# Install packages in venv
pip install -r requirements.txt
```

## Build/Compilation Issues

### CMake Not Found

**Problem**: `cmake: command not found`.

**Solution**:
```powershell
# Windows: Install with winget
winget install Kitware.CMake

# Or download from cmake.org
```

```bash
# Linux: Install with package manager
sudo apt install cmake
```

### Compiler Not Found

**Problem**: Build fails with "no compiler found".

**Solution**:
```powershell
# Windows: Install Visual Studio Build Tools
# Or install Visual Studio Community with C++ workload
```

```bash
# Linux: Install build essentials
sudo apt install build-essential
```

### Build Fails

**Problem**: CMake configure or build fails.

**Solution**:
- Check compiler is available: `cl` (Windows) or `gcc` (Linux)
- Verify project path is correct
- Try clean build: delete `build` directory and reconfigure
- Check error messages for specific issues

## Performance Issues

### Results Below Target

**Problem**: Performance retention below 85%.

**Possible Causes**:
1. Other applications running
2. System thermal throttling
3. Power plan not set to High Performance
4. Insufficient RAM
5. Background processes

**Solutions**:
```powershell
# Check running processes
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Set power plan to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Check available RAM
Get-WmiObject Win32_ComputerSystem | Select-Object TotalPhysicalMemory
```

### System Becomes Unresponsive

**Problem**: System freezes or becomes very slow during demo.

**Solutions**:
- Reduce workload intensity (use `-QuickTest` flag)
- Close other applications
- Check system temperature
- Ensure adequate cooling
- Reduce number of concurrent processes

### High CPU Usage

**Problem**: CPU usage at 100% during demo.

**Note**: This is expected during LLM inference, but should not cause UI lag on Strix Halo.

**Solutions**:
- Verify QoS is working (CPU should remain responsive)
- Check if other processes are competing
- Reduce LLM model size if needed
- Use fewer iterations in quick test mode

## Application-Specific Issues

### Excel Not Available

**Problem**: Office demo can't find or use Excel.

**Solutions**:
- Install Microsoft Office
- Or use LibreOffice Calc (requires script modification)
- Or manually test while script runs meeting assistant
- Script will provide manual testing instructions

### Video Editor Not Responding

**Problem**: Video editor becomes slow or unresponsive.

**Solutions**:
- Ensure adequate RAM (32GB+ recommended)
- Close other applications
- Update GPU drivers
- Reduce preview resolution
- Check system temperature

### VS Code Issues

**Problem**: VS Code becomes laggy during developer demo.

**Solutions**:
- Close unnecessary extensions
- Reduce workspace size
- Check for extension conflicts
- Restart VS Code
- Verify system has adequate resources

## Network Issues

### Model Download Slow

**Problem**: `ollama pull` is very slow.

**Solutions**:
- Check internet connection speed
- Try at different time (network congestion)
- Use wired connection if possible
- Check firewall settings

### API Connection Fails

**Problem**: Scripts can't connect to Ollama API.

**Solutions**:
- Verify Ollama service is running
- Check firewall isn't blocking localhost
- Verify Ollama is listening on correct port (default 11434)
- Restart Ollama service

## Logging Issues

### Logs Not Created

**Problem**: No log files in `logs/` directory.

**Solutions**:
```powershell
# Check if logs directory exists
Test-Path logs

# Create if missing
New-Item -ItemType Directory -Path logs -Force

# Check write permissions
Test-Path logs -IsValid
```

### Log Files Empty

**Problem**: Log files are created but empty.

**Solutions**:
- Check script execution completed
- Verify Write-Log function is working
- Check disk space
- Verify file permissions

## Platform-Specific Issues

### Windows-Specific

**PowerShell Version**:
- Requires PowerShell 5.1 or later
- Check version: `$PSVersionTable.PSVersion`

**COM Automation**:
- Excel automation requires Excel to be installed
- May require running as Administrator
- Check COM permissions if issues occur

### Linux-Specific

**Perf Permissions**:
```bash
# Add user to perf group (if exists)
sudo usermod -aG perf $USER

# Or run with sudo (not recommended)
sudo perf stat ...
```

**Audio/Video**:
- May require additional codecs
- Install: `sudo apt install ffmpeg`

## Getting Help

### Collecting Debug Information

Before asking for help, collect:

1. **System Information**:
```powershell
.\scripts\verify_setup.ps1 > debug_info.txt
```

2. **Error Messages**:
- Copy full error output
- Include stack traces if available

3. **Log Files**:
- Check `logs/` directory
- Include relevant log files

4. **Environment**:
- OS version
- Python version
- Ollama version
- Available RAM/disk space

### Common Error Messages

**"Access Denied"**:
- Run PowerShell as Administrator
- Check file permissions
- Verify antivirus isn't blocking

**"Out of Memory"**:
- Close other applications
- Reduce workload size
- Check available RAM

**"Connection Refused"**:
- Verify service is running (Ollama, etc.)
- Check firewall settings
- Verify port is not in use

## Still Having Issues?

1. Review relevant walkthrough guide:
   - [Developer Demo Walkthrough](dev_qos_walkthrough.md)
   - [Office Demo Walkthrough](office_qos_walkthrough.md)
   - [Creator Demo Walkthrough](creator_qos_walkthrough.md)

2. Check setup guides:
   - [Windows Setup](../env/windows_setup.md)
   - [Linux Setup](../env/linux_setup.md)

3. Verify all prerequisites are met:
```powershell
.\scripts\verify_setup.ps1
```

4. Try quick test mode first:
```powershell
.\scripts\dev_qos_demo.ps1 -QuickTest
```

