# Comprehensive Memory QoS Demonstration

## Overview

The **Comprehensive Memory QoS Demo** (`memory_qos_demo.sh`) is an extensive test designed to clearly demonstrate Strix Halo's memory bandwidth protection capabilities under heavy, sustained load.

## What Makes This Test More Extensive

### 1. **Four-Phase Test Structure**

Unlike simpler tests, this demo runs through four distinct phases:

1. **Baseline Phase** (20% of duration)
   - Memory-intensive workload only
   - Establishes baseline memory availability
   - Continuous builds + memory operations

2. **Transition Phase** (30% of duration)
   - Memory workload + LLM starting
   - Shows how system handles LLM initialization
   - Monitors memory during transition

3. **Contended Phase** (30% of duration)
   - Both workloads fully active
   - Maximum memory bandwidth contention
   - **This is where QoS protection is most critical**

4. **Recovery Phase** (20% of duration)
   - LLM stopped, workload continues
   - Shows system recovery
   - Validates memory returns to baseline

### 2. **More Intensive Workloads**

**Memory-Intensive Workload**:
- Continuous CMake builds (CPU + memory)
- Python memory operations (100MB chunks, 10 iterations)
- Aggressive memory access patterns
- Designed to consume significant memory bandwidth

**LLM Workload**:
- More frequent requests (0.2s interval vs 0.5s)
- Longer, more complex prompts
- Continuous inference loop
- Maximum memory bandwidth usage

### 3. **Comprehensive Metrics Collection**

Collects **25+ metrics** including:
- Memory: Available, Used, Cached, Buffers, Swap
- CPU: Usage, Frequency, User/System time
- I/O: Read/Write bandwidth, I/O counts
- System: Load averages (1m, 5m, 15m), Context switches, Interrupts
- Processes: Count, Threads
- Disk: Usage percentage

### 4. **Higher Sampling Rate**

- **0.5 second intervals** (vs 1 second in realtime monitor)
- More data points for better analysis
- Captures rapid changes in memory state

### 5. **Phase-Aware Analysis**

- Metrics tagged by phase
- Phase-specific statistics
- Clear visualization of phase transitions
- Recovery validation

## How to Run

### Basic Usage

```bash
# Run with default duration (120 seconds = 2 minutes)
./scripts/memory_qos_demo.sh

# Custom duration (minimum 60 seconds recommended)
./scripts/memory_qos_demo.sh --duration 180
```

### What Happens

1. **Phase 1 (Baseline)**: ~24 seconds
   - Memory-intensive workload starts
   - Establishes baseline metrics
   - No LLM running

2. **Phase 2 (Transition)**: ~36 seconds
   - LLM workload starts
   - System transitions to contended state
   - Monitors memory during transition

3. **Phase 3 (Contended)**: ~36 seconds
   - Both workloads fully active
   - Maximum memory contention
   - **Key phase for QoS demonstration**

4. **Phase 4 (Recovery)**: ~24 seconds
   - LLM stops
   - System recovers
   - Memory returns toward baseline

## Visualizing Results

### Generate Comprehensive Visualization

```bash
# Use the latest CSV file
LATEST_CSV=$(ls -t logs/memory_qos_metrics_*.csv | head -1)
python3 scripts/visualize_memory_qos.py --metrics-file "$LATEST_CSV"
```

### What the Visualization Shows

1. **Memory Availability Over Time** (Primary Metric)
   - Shows stability across all phases
   - Phase background coloring
   - Clear phase labels

2. **Memory Usage Breakdown**
   - Used, Cached, Buffers
   - Shows memory allocation patterns

3. **Swap Usage**
   - Should stay low (<5%)
   - Indicates memory pressure

4. **CPU Usage**
   - Shows CPU contention
   - Separate from memory QoS

5. **I/O Bandwidth**
   - Fair sharing demonstration
   - Memory bandwidth proxy

6. **System Load**
   - 1-minute, 5-minute, 15-minute averages
   - Overall system stress

7. **CPU Frequency**
   - Should maintain under load
   - Performance indicator

8. **Memory Retention by Phase** (Key Chart)
   - Bar chart showing retention for each phase
   - Target lines (95%, 85%)
   - Clear visual of QoS effectiveness

9. **Phase Comparison Table**
   - Summary statistics for each phase
   - Easy comparison
   - Color-coded by phase

## Expected Results

### With Strix Halo QoS (Expected)

**Memory Retention by Phase**:
- Baseline: 100% (reference)
- Transition: ≥95% (minimal impact)
- **Contended: ≥95%** (key metric - QoS protection)
- Recovery: ≥98% (quick recovery)

**Memory Availability**:
- Should remain stable throughout
- No significant drops when LLM starts
- Quick recovery when LLM stops

**Swap Usage**:
- Should stay <5% (ideally <1%)
- No swap thrashing

### Without QoS (Hypothetical)

- Memory availability would drop significantly
- Swap usage would increase
- System would become unresponsive
- Recovery would be slow

## Key Advantages Over Other Tests

### vs. Real-time Monitor

1. **More phases**: 4 phases vs 2
2. **More intensive**: Aggressive memory workloads
3. **More metrics**: 25+ vs 12
4. **Phase analysis**: Tagged metrics by phase
5. **Recovery validation**: Shows system recovery

### vs. Developer Demo

1. **Memory-focused**: Measures memory, not build time
2. **More comprehensive**: Multiple metrics, not just one
3. **Phase-based**: Clear phase transitions
4. **Longer duration**: More data points
5. **Recovery phase**: Validates system behavior

## Interpretation Guide

### Memory Retention ≥95%
✅ **EXCELLENT**: QoS is working perfectly
- No memory starvation
- Memory bandwidth protected
- System maintains responsiveness

### Memory Retention 85-95%
✅ **GOOD**: QoS is providing protection
- Minimal memory impact
- Some variation acceptable
- System remains functional

### Memory Retention <85%
⚠️ **NEEDS ATTENTION**: May indicate:
- QoS not fully active
- Extremely aggressive workload
- System configuration issue

### Swap Usage >5%
⚠️ **WARNING**: Memory pressure detected
- May indicate memory constraints
- System may be swapping
- Check available memory

## Use Cases

This comprehensive test is ideal for:

1. **Product Demonstrations**
   - Clear visual proof of QoS effectiveness
   - Multiple phases show complete picture
   - Professional visualization

2. **Performance Validation**
   - Verify QoS is working correctly
   - Identify configuration issues
   - Benchmark system capabilities

3. **Comparative Analysis**
   - Compare different systems
   - Test QoS settings
   - Validate improvements

4. **Documentation**
   - Generate reports with comprehensive data
   - Show before/after scenarios
   - Support technical discussions

## Tips for Best Results

1. **Run when system is idle**
   - Close unnecessary applications
   - Reduce background load
   - Clear caches if needed

2. **Use appropriate duration**
   - Minimum 60 seconds (too short for meaningful data)
   - Recommended 120 seconds (good balance)
   - 180+ seconds for very detailed analysis

3. **Monitor system resources**
   - Ensure sufficient memory available
   - Check CPU temperature
   - Monitor disk space

4. **Run multiple iterations**
   - Establish statistical baseline
   - Account for variability
   - Validate consistency

## Output Files

- **CSV Metrics**: `logs/memory_qos_metrics_YYYYMMDD_HHMMSS.csv`
- **Log File**: `logs/memory_qos_demo_YYYYMMDD_HHMMSS.log`
- **Visualization**: `logs/memory_qos_comprehensive_*.png` (when generated)

## Next Steps

After running the demo:

1. **Generate visualization**:
   ```bash
   python3 scripts/visualize_memory_qos.py --metrics-file logs/memory_qos_metrics_*.csv
   ```

2. **Analyze results**:
   - Check memory retention by phase
   - Verify swap usage stays low
   - Confirm stable memory availability

3. **Compare with other tests**:
   - Real-time monitor results
   - Developer demo results
   - Establish baseline expectations

---

*This comprehensive test provides the most extensive demonstration of Strix Halo's memory QoS capabilities.*

