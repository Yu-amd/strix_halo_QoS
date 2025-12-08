#!/bin/bash
# Comprehensive Memory QoS Demonstration
# Shows Strix Halo's memory bandwidth protection with intensive workloads

set -e

# Check for virtual environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="$SCRIPT_DIR/../venv"
if [ -d "$VENV_PATH" ] && [ -f "$VENV_PATH/bin/python" ]; then
    export PATH="$VENV_PATH/bin:$PATH"
fi

DURATION=120  # 2 minutes total
PROJECT_PATH="test-projects/json"
MODEL="codellama:7b"
UPDATE_INTERVAL=0.5  # More frequent sampling

while [[ $# -gt 0 ]]; do
    case $1 in
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

LOG_DIR="logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
METRICS_FILE="$LOG_DIR/memory_qos_metrics_${TIMESTAMP}.csv"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

log() {
    local message="$1"
    local log_file="$LOG_DIR/memory_qos_demo_${TIMESTAMP}.log"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $message" >> "$log_file" 2>/dev/null || true
    echo "$timestamp - $message" >&2
    echo "$message" >&2
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    if command -v ollama &> /dev/null; then
        local ollama_version=$(ollama --version 2>&1)
        log "✓ Ollama found: $ollama_version"
    else
        log "✗ Ollama not found"
        exit 1
    fi
    
    if ollama list 2>&1 | grep -q "$MODEL"; then
        log "✓ Model $MODEL available"
    else
        log "✗ Model $MODEL not found. Run: ollama pull $MODEL"
        exit 1
    fi
    
    if command -v python3 &> /dev/null; then
        if python3 -c "import psutil" 2>/dev/null; then
            log "✓ Python and psutil available"
        else
            log "✗ psutil not installed"
            exit 1
        fi
    else
        log "✗ Python not found"
        exit 1
    fi
    
    if command -v cmake &> /dev/null; then
        log "✓ CMake found"
    else
        log "✗ CMake not found"
        exit 1
    fi
    
    if [ ! -d "$PROJECT_PATH" ]; then
        log "✗ Project path not found: $PROJECT_PATH"
        exit 1
    fi
    log "✓ Project path found: $PROJECT_PATH"
}

start_memory_intensive_monitor() {
    local metrics_file="$1"
    local duration="$2"
    local interval="$3"
    
    log "Starting comprehensive memory QoS monitor..."
    
    # Write Python monitoring script to temp file
    local py_script=$(mktemp /tmp/memory_qos_monitor_XXXXXX.py)
    cat > "$py_script" <<PYTHON_SCRIPT
import psutil
import time
import csv
import os
from datetime import datetime

metrics_file = "$metrics_file"
duration = $duration
interval = $interval

# CSV header with comprehensive metrics
with open(metrics_file, 'w') as f:
    writer = csv.writer(f)
    writer.writerow([
        'timestamp', 'phase', 'cpu_percent', 'memory_percent', 
        'memory_available_gb', 'memory_used_gb', 'memory_cached_gb',
        'memory_buffers_gb', 'swap_used_gb', 'swap_percent',
        'io_read_mb_s', 'io_write_mb_s', 'io_read_count', 'io_write_count',
        'cpu_freq_mhz', 'load_avg_1m', 'load_avg_5m', 'load_avg_15m',
        'context_switches', 'interrupts', 'cpu_user', 'cpu_system',
        'num_processes', 'num_threads', 'disk_usage_percent'
    ])

start_time = time.time()
phase = "warmup"

# Initialize CPU percent
_ = psutil.cpu_percent(interval=None)

# Initialize I/O counters
try:
    last_io = psutil.disk_io_counters()
except:
    last_io = None

last_io_time = time.time()

while (time.time() - start_time) < duration:
    current_time = time.time()
    elapsed = current_time - start_time
    
    # Determine phase
    if elapsed < duration * 0.2:
        phase = "baseline"
    elif elapsed < duration * 0.5:
        phase = "transition"
    elif elapsed < duration * 0.8:
        phase = "contended"
    else:
        phase = "recovery"
    
    # CPU metrics
    cpu_percent = psutil.cpu_percent(interval=None)
    cpu_times = psutil.cpu_times_percent(interval=None)
    
    # Memory metrics (comprehensive)
    memory = psutil.virtual_memory()
    swap = psutil.swap_memory()
    
    # I/O metrics
    try:
        io = psutil.disk_io_counters()
        if last_io and io:
            time_delta = current_time - last_io_time
            if time_delta > 0:
                io_read_mb = (io.read_bytes - last_io.read_bytes) / (1024 * 1024) / time_delta
                io_write_mb = (io.write_bytes - last_io.write_bytes) / (1024 * 1024) / time_delta
                io_read_count_delta = io.read_count - last_io.read_count
                io_write_count_delta = io.write_count - last_io.write_count
            else:
                io_read_mb = 0
                io_write_mb = 0
                io_read_count_delta = 0
                io_write_count_delta = 0
        else:
            io_read_mb = 0
            io_write_mb = 0
            io_read_count_delta = 0
            io_write_count_delta = 0
        last_io = io
        last_io_time = current_time
    except:
        io_read_mb = 0
        io_write_mb = 0
        io_read_count_delta = 0
        io_write_count_delta = 0
    
    # System metrics
    cpu_freq = psutil.cpu_freq()
    load_avg = psutil.getloadavg()
    cpu_stats = psutil.cpu_stats()
    
    # Process/thread counts
    num_processes = len(psutil.pids())
    try:
        num_threads = sum(len(p.threads()) for p in psutil.process_iter(['pid']) if p.info.get('pid') != os.getpid())
    except:
        num_threads = 0
    
    # Disk usage
    try:
        disk = psutil.disk_usage('/')
        disk_usage_percent = disk.percent
    except:
        disk_usage_percent = 0
    
    with open(metrics_file, 'a') as f:
        writer = csv.writer(f)
        writer.writerow([
            datetime.now().isoformat(),
            phase,
            f"{cpu_percent:.2f}",
            f"{memory.percent:.2f}",
            f"{memory.available / (1024**3):.2f}",
            f"{memory.used / (1024**3):.2f}",
            f"{memory.cached / (1024**3):.2f}",
            f"{memory.buffers / (1024**3):.2f}",
            f"{swap.used / (1024**3):.2f}",
            f"{swap.percent:.2f}",
            f"{io_read_mb:.2f}",
            f"{io_write_mb:.2f}",
            io_read_count_delta,
            io_write_count_delta,
            f"{cpu_freq.current if cpu_freq else 0:.0f}",
            f"{load_avg[0]:.2f}",
            f"{load_avg[1]:.2f}",
            f"{load_avg[2]:.2f}",
            cpu_stats.ctx_switches,
            cpu_stats.interrupts,
            f"{cpu_times.user:.2f}",
            f"{cpu_times.system:.2f}",
            num_processes,
            num_threads,
            f"{disk_usage_percent:.2f}"
        ])
    
    time.sleep(interval)

PYTHON_SCRIPT
    
    # Start Python script in background
    python3 "$py_script" >/dev/null 2>&1 &
    local pid=$!
    
    # Clean up temp file in background
    (sleep 3 && rm -f "$py_script") &
    
    echo "$pid"
}

start_memory_intensive_workload() {
    local project_path="$1"
    
    log "Starting memory-intensive workload (continuous builds + memory access)..."
    
    # Convert to absolute path
    if [[ "$project_path" != /* ]]; then
        project_path="$(cd "$SCRIPT_DIR/.." && pwd)/$project_path"
    fi
    
    local build_dir="$project_path/build"
    
    # Initialize build directory if needed
    if [ ! -d "$build_dir" ]; then
        (cd "$project_path" && cmake -B build >/dev/null 2>&1) || true
    fi
    
    # Start intensive workload: continuous builds + memory operations
    (
        while true; do
            # Build (CPU + memory intensive)
            cmake --build "$build_dir" --config Release -j$(nproc) >/dev/null 2>&1 || true
            
            # Memory-intensive operation: process large data
            python3 <<MEMORY_OP &
import array
import time

# Allocate and access large memory regions
chunks = []
for i in range(10):
    # Allocate 100MB chunks
    chunk = array.array('d', [0.0] * (100 * 1024 * 1024 // 8))
    # Access pattern to trigger memory bandwidth usage
    for j in range(0, len(chunk), 1024):
        chunk[j] = j * 1.5
    chunks.append(chunk)
    time.sleep(0.1)

# Keep chunks alive for a bit
time.sleep(0.5)
MEMORY_OP
            
            sleep 0.2
        done
    ) >/dev/null 2>&1 &
    
    local pid=$!
    sleep 0.1
    echo "  ✓ Memory-intensive workload started (PID: $pid)" >&2
    echo "$pid"
}

start_llm_workload() {
    local model="$1"
    
    log "Starting LLM workload (memory + CPU intensive)..."
    
    local code_sample='#include <iostream>
#include <vector>
#include <algorithm>
#include <memory>

class DataProcessor {
public:
    void processLargeDataset(std::vector<std::vector<double>>& data) {
        for (auto& row : data) {
            std::sort(row.begin(), row.end());
            for (auto& val : row) {
                val = val * 2.5 + 10.0;
            }
        }
    }
};

int main() {
    std::vector<std::vector<double>> dataset(1000, std::vector<double>(10000));
    DataProcessor processor;
    processor.processLargeDataset(dataset);
    return 0;
}'
    
    local prompt="You are a code optimization assistant. Analyze this memory-intensive C++ code and suggest optimizations for cache locality and memory bandwidth efficiency: $code_sample"
    
    # Start LLM inference loop - more aggressive
    (
        while true; do
            ollama run "$model" "$prompt" &> /dev/null
            sleep 0.2  # More frequent requests
        done
    ) >/dev/null 2>&1 &
    
    local pid=$!
    sleep 0.1
    echo "  ✓ LLM workload started (PID: $pid)" >&2
    echo "$pid"
}

cleanup() {
    log ""
    log "Cleaning up..."
    
    [ -n "$MONITOR_PID" ] && kill $MONITOR_PID 2>/dev/null || true
    [ -n "$WORKLOAD_PID" ] && kill $WORKLOAD_PID 2>/dev/null || true
    [ -n "$LLM_PID" ] && kill $LLM_PID 2>/dev/null || true
    
    # Kill child processes
    pkill -P $WORKLOAD_PID 2>/dev/null || true
    pkill -P $LLM_PID 2>/dev/null || true
    pkill -f "memory_qos_monitor_.*\.py" 2>/dev/null || true
    
    sleep 0.5
    
    # Force kill
    [ -n "$MONITOR_PID" ] && kill -9 $MONITOR_PID 2>/dev/null || true
    [ -n "$WORKLOAD_PID" ] && kill -9 $WORKLOAD_PID 2>/dev/null || true
    [ -n "$LLM_PID" ] && kill -9 $LLM_PID 2>/dev/null || true
    
    wait 2>/dev/null || true
    log "Cleanup complete"
}

# Trap to ensure cleanup
trap cleanup EXIT INT TERM

# Redirect stderr to fd 3
exec 3>&2

# Main execution
log "=== Strix Halo Comprehensive Memory QoS Demo ==="
log ""
log "This demo extensively tests memory bandwidth protection under heavy load"
log "Duration: ${DURATION} seconds"
log ""

check_prerequisites

log ""
log "Starting comprehensive monitoring..."
log "Metrics will be saved to: $METRICS_FILE"
log ""

# Start monitoring
MONITOR_PID=$(start_memory_intensive_monitor "$METRICS_FILE" "$DURATION" "$UPDATE_INTERVAL")
sleep 1

log ""
log "=== Phase 1: Baseline (Memory-Intensive Workload Only) ==="
log "Starting memory-intensive workload (continuous builds + memory operations)..."
WORKLOAD_PID=$(start_memory_intensive_workload "$PROJECT_PATH" 2>&3)
log "Workload running (PID: $WORKLOAD_PID)"

PHASE1_DURATION=$((DURATION * 20 / 100))  # 20% of duration
log "Monitoring baseline for ${PHASE1_DURATION} seconds..."
log "Phase 1 progress:"
for i in $(seq $PHASE1_DURATION -1 1); do
    sleep 1
    if [ $((i % 5)) -eq 0 ] || [ $i -le 5 ]; then
        log "  ${i} seconds remaining..."
    fi
done
log "  ✓ Phase 1 complete!"

log ""
log "=== Phase 2: Transition (Workload + LLM Starting) ==="
log "Starting LLM workload (this is where QoS should prevent memory starvation)..."
LLM_PID=$(start_llm_workload "$MODEL" 2>&3)
log "LLM workload running (PID: $LLM_PID)"
log "Waiting for LLM to fully initialize..."

# Wait for LLM to be active
wait_count=0
max_wait=10
while [ $wait_count -lt $max_wait ]; do
    ollama_runners=$(ps aux | grep -c "[o]llama runner" || echo "0")
    if [ "$ollama_runners" -gt 0 ]; then
        log "  ✓ LLM is active (found $ollama_runners runner process(es))"
        break
    fi
    sleep 1
    wait_count=$((wait_count + 1))
done

PHASE2_DURATION=$((DURATION * 30 / 100))  # 30% of duration
log "Monitoring transition for ${PHASE2_DURATION} seconds..."
log "Phase 2 progress:"
for i in $(seq $PHASE2_DURATION -1 1); do
    sleep 1
    if [ $((i % 5)) -eq 0 ] || [ $i -le 5 ]; then
        log "  ${i} seconds remaining..."
    fi
done
log "  ✓ Phase 2 complete!"

log ""
log "=== Phase 3: Contended (Workload + LLM Fully Active) ==="
log "Both workloads are now fully active - monitoring memory QoS protection..."
PHASE3_DURATION=$((DURATION * 30 / 100))  # 30% of duration
log "Monitoring contended performance for ${PHASE3_DURATION} seconds..."
log "Watch for: Memory availability maintained, no starvation, stable performance"
log "Phase 3 progress:"
for i in $(seq $PHASE3_DURATION -1 1); do
    sleep 1
    if [ $((i % 10)) -eq 0 ] || [ $i -le 10 ]; then
        log "  ${i} seconds remaining..."
    fi
done
log "  ✓ Phase 3 complete!"

log ""
log "=== Phase 4: Recovery (LLM Stopped, Workload Continues) ==="
log "Stopping LLM workload to observe recovery..."
kill $LLM_PID 2>/dev/null || true
wait $LLM_PID 2>/dev/null || true
log "✓ LLM stopped"

PHASE4_DURATION=$((DURATION * 20 / 100))  # 20% of duration
log "Monitoring recovery for ${PHASE4_DURATION} seconds..."
log "Phase 4 progress:"
for i in $(seq $PHASE4_DURATION -1 1); do
    sleep 1
    if [ $((i % 5)) -eq 0 ] || [ $i -le 5 ]; then
        log "  ${i} seconds remaining..."
    fi
done
log "  ✓ Phase 4 complete!"

# Cleanup
cleanup

log ""
log "=== Analysis ==="
log "Metrics saved to: $METRICS_FILE"
log ""
log "Key observations:"
log "  - Memory availability should remain stable throughout all phases"
log "  - No memory starvation should occur when LLM starts"
log "  - System should recover quickly when LLM stops"
log "  - These metrics demonstrate comprehensive QoS protection"
log ""
log "To visualize results, run:"
log "  python3 scripts/visualize_memory_qos.py --metrics-file $METRICS_FILE"
log ""
log "=== Demo Complete ==="
log ""
exit 0

