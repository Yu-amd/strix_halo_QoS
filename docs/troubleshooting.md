# Troubleshooting Guide

Common issues and solutions for Strix Halo QoS.

## General Issues

### Scripts Won't Run

**Problem**: Scripts show permission errors.

**Solution**:
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run with explicit bash
bash scripts/memory_qos_demo.sh --duration 600
```

### Logs Directory Not Created

**Problem**: Scripts fail to create logs directory.

**Solution**:
```bash
# Manually create logs directory
mkdir -p logs
```

### Path Issues

**Problem**: Scripts can't find files or directories.

**Solution**:
- Ensure you're running scripts from the repository root
- Use absolute paths if needed
- Check file paths use forward slashes (`/`)

## Ollama Issues

### Ollama Not Found

**Problem**: `ollama: command not found`.

**Solution**:
```bash
# Check installation
which ollama

# Reinstall if needed
curl -fsSL https://ollama.ai/install.sh | sh
```

### Ollama Service Not Running

**Problem**: Ollama commands hang or fail to connect.

**Solution**:
```bash
# Check service
systemctl status ollama

# Start service
sudo systemctl start ollama

# Or run in foreground for debugging
ollama serve
```

### Model Not Available

**Problem**: Script reports model not found.

**Solution**:
```bash
# List available models
ollama list

# Pull required model
ollama pull codellama:7b
```

### Model Download Fails

**Problem**: `ollama pull` fails or is very slow.

**Solution**:
- Check internet connection
- Try again (may be temporary network issue)
- Check available disk space (models are several GB)
- Verify Ollama has write permissions

## Python Issues

### Python Not Found

**Problem**: `python3: command not found`.

**Solution**:
```bash
# Install Python
sudo apt install python3 python3-pip python3-venv
```

### Module Not Found

**Problem**: `ModuleNotFoundError: No module named 'psutil'` or similar.

**Solution**:
```bash
# Install required packages
pip install -r requirements.txt

# Or install individually
pip install psutil matplotlib seaborn
```

### Virtual Environment Issues

**Problem**: Packages installed but not found.

**Solution**:
```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install packages in venv
pip install -r requirements.txt
```

## Build/Compilation Issues

### CMake Not Found

**Problem**: `cmake: command not found`.

**Solution**:
```bash
# Install with package manager
sudo apt install cmake build-essential
```

### Compiler Not Found

**Problem**: Build fails with "no compiler found".

**Solution**:
```bash
# Install build essentials
sudo apt install build-essential gcc g++
```

### Build Fails

**Problem**: CMake configure or build fails.

**Solution**:
- Check compiler is available: `gcc --version`
- Verify project path is correct
- Try clean build: delete `build` directory and reconfigure
- Check error messages for specific issues

## Performance Issues

### Results Below Target

**Problem**: Memory retention below 85%.

**Possible Causes**:
1. Other applications running
2. System thermal throttling
3. Power plan not set to performance mode
4. Insufficient RAM
5. Background processes

**Solutions**:
```bash
# Check running processes
ps aux | sort -k3 -rn | head -10

# Check available RAM
free -h

# Check CPU frequency
cat /proc/cpuinfo | grep MHz

# Close unnecessary applications
```

### System Becomes Unresponsive

**Problem**: System freezes or becomes very slow during demo.

**Solutions**:
- Reduce demo duration (use shorter `--duration`)
- Close other applications
- Check system temperature
- Ensure adequate cooling
- Check available RAM: `free -h`

### High CPU Usage

**Problem**: CPU usage at 100% during demo.

**Note**: This is expected during LLM inference, but should not cause UI lag on Strix Halo.

**Solutions**:
- Verify QoS is working (CPU should remain responsive)
- Check if other processes are competing
- Reduce LLM model size if needed
- Use shorter duration for testing

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
- Verify Ollama service is running: `systemctl status ollama`
- Check firewall isn't blocking localhost
- Verify Ollama is listening on correct port (default 11434)
- Restart Ollama service: `sudo systemctl restart ollama`

## Logging Issues

### Logs Not Created

**Problem**: No log files in `logs/` directory.

**Solutions**:
```bash
# Check if logs directory exists
ls -la logs/

# Create if missing
mkdir -p logs

# Check write permissions
touch logs/test.txt && rm logs/test.txt
```

### Log Files Empty

**Problem**: Log files are created but empty.

**Solutions**:
- Check script execution completed
- Verify script has write permissions
- Check disk space: `df -h`
- Verify file permissions

## Platform-Specific Issues

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

Before opening an issue on GitHub, please collect:

1. **System Information**:
```bash
uname -a > debug_info.txt
python3 --version >> debug_info.txt
ollama --version >> debug_info.txt
free -h >> debug_info.txt
df -h >> debug_info.txt
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

**"Permission Denied"**:
- Check file permissions: `chmod +x scripts/*.sh`
- Verify antivirus isn't blocking
- Check SELinux/apparmor if enabled

**"Out of Memory"**:
- Close other applications
- Reduce demo duration
- Check available RAM: `free -h`

**"Connection Refused"**:
- Verify Ollama service is running: `systemctl status ollama`
- Check firewall settings
- Verify port is not in use: `netstat -tuln | grep 11434`

## Still Having Issues?

1. Review setup guides:
   - [Linux Setup](../env/linux_setup.md)
   - [Installation Guide](../INSTALLATION.md)

2. Check all prerequisites are met:
   - Ollama installed and running
   - Python 3.8+ with required packages
   - CMake and build tools installed
   - Test project available

3. Try a shorter test first:
```bash
./scripts/memory_qos_demo.sh --duration 60
```

4. Open an issue on GitHub with the debug information collected above.
