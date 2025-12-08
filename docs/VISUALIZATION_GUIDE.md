# Comprehensive Memory QoS Visualization - Graph Explanations

This guide explains all the graphs in the comprehensive memory QoS visualization image.

## Dashboard Layout

The visualization contains **9 panels** arranged in a grid:
- **Top row (full width)**: Memory Availability (primary metric)
- **Second row (3 panels)**: Memory Usage Breakdown, Swap Usage, CPU Usage
- **Third row (3 panels)**: I/O Bandwidth, System Load, CPU Frequency
- **Fourth row (full width)**: Memory Retention by Phase (you understand this)
- **Fifth row (full width)**: Phase Comparison Summary table (you understand this)

---

## Graph 1: Memory Availability - Key QoS Metric
**Location**: Top row, full width  
**Title**: "Memory Availability - Key QoS Metric (Higher is Better, Should Remain Stable)"

### What It Shows
- **Green line**: Available memory in GB over time
- **Phase backgrounds**: Colored backgrounds showing which phase is active
- **Phase labels**: Text labels (BASELINE, TRANSITION, CONTENDED, RECOVERY) at the top

### What to Look For
✅ **Good**: 
- Line stays relatively flat and stable
- No significant drops when transitioning to CONTENDED phase
- Quick recovery when entering RECOVERY phase

⚠️ **Concerning**:
- Sharp drops when LLM starts (CONTENDED phase)
- Memory doesn't recover in RECOVERY phase
- Overall downward trend

### Why It Matters
This is the **primary QoS metric**. It directly shows whether memory bandwidth is being protected. If this stays stable, QoS is working correctly.

---

## Graph 2: Memory Usage Breakdown
**Location**: Second row, left panel  
**Title**: "Memory Usage Breakdown (Lower is Better)"

### What It Shows
Three lines showing different types of memory usage:
- **Red line**: Used memory (actively used by applications)
- **Orange line**: Cached memory (files cached in memory for faster access)
- **Yellow line**: Buffers (temporary data buffers)

### What to Look For
✅ **Good**:
- Used memory increases when workloads start (expected)
- Cached memory may increase (OS optimization)
- Buffers stay relatively low
- No sudden spikes in used memory

⚠️ **Concerning**:
- Used memory approaches total system memory
- Cached memory drops significantly (indicates memory pressure)
- Buffers spike unexpectedly

### Why It Matters
Shows **how memory is allocated** across different categories. Helps understand if memory pressure is coming from applications (used) or system optimization (cached).

---

## Graph 3: Swap Usage - Memory Pressure Indicator
**Location**: Second row, middle panel  
**Title**: "Swap Usage - Memory Pressure Indicator (Lower is Better)"

### What It Shows
- **Purple line**: Percentage of swap space being used
- **Red dashed line**: Warning threshold at 5%

### What to Look For
✅ **Good**:
- Swap usage stays very low (<1-2%)
- No increase when LLM starts
- Stays well below the 5% warning line

⚠️ **Concerning**:
- Swap usage increases significantly (>5%)
- Spikes when entering CONTENDED phase
- System is swapping to disk (very bad for performance)

### Why It Matters
Swap usage is a **critical indicator of memory pressure**. When physical memory is exhausted, the OS uses swap (disk), which is extremely slow. High swap usage means memory starvation is occurring.

---

## Graph 4: CPU Usage
**Location**: Second row, right panel  
**Title**: "CPU Usage (Stability Matters)"

### What It Shows
- **Blue line**: Overall CPU usage percentage (0-100%)

### What to Look For
✅ **Good**:
- CPU usage increases when workloads start (expected)
- Usage is stable (not wildly fluctuating)
- No sudden drops to 0% (which would indicate blocking)

⚠️ **Concerning**:
- CPU usage drops to very low levels (may indicate processes are blocked waiting for memory)
- Extreme fluctuations
- CPU maxes out at 100% and stays there (bottleneck)

### Why It Matters
Shows **CPU activity**. While not directly a memory QoS metric, it helps identify if processes are being blocked. If CPU drops when memory contention starts, it may indicate memory starvation is causing processes to wait.

---

## Graph 5: I/O Bandwidth - Fair Sharing
**Location**: Third row, left panel  
**Title**: "I/O Bandwidth - Fair Sharing (Higher is Better)"

### What It Shows
Two lines showing disk I/O activity:
- **Blue line**: Read bandwidth (MB/s)
- **Red line**: Write bandwidth (MB/s)

### What to Look For
✅ **Good**:
- I/O bandwidth increases when workloads are active (expected)
- Both workloads get fair share of I/O bandwidth
- No one workload dominates

⚠️ **Concerning**:
- I/O bandwidth drops to near zero (may indicate blocking)
- One workload completely starves the other
- Extreme spikes or drops

### Why It Matters
I/O bandwidth is a **proxy for memory bandwidth** in some cases. It also shows whether the system is fairly sharing resources. If I/O is blocked, it may indicate memory-related issues.

---

## Graph 6: System Load Average
**Location**: Third row, middle panel  
**Title**: "System Load Average (Lower is Better)"

### What It Shows
Three lines showing system load over different time windows:
- **Green line**: 1-minute load average
- **Orange line**: 5-minute load average  
- **Red line**: 15-minute load average

### What Is Load Average?
Load average represents the average number of processes that are either:
- Running (using CPU)
- Waiting to run (ready but waiting for CPU)
- Waiting for I/O (blocked on disk/network)

**Interpretation**:
- Load of 1.0 on a single-core system = CPU fully utilized
- Load of 2.0 on a dual-core system = CPU fully utilized
- Load > number of cores = system is overloaded

### What to Look For
✅ **Good**:
- Load increases when workloads start (expected)
- Load is manageable (not extremely high)
- Load decreases in RECOVERY phase

⚠️ **Concerning**:
- Load becomes extremely high (>10x number of CPU cores)
- Load doesn't decrease when workloads stop
- 1-minute load much higher than 15-minute (indicates recent spike)

### Why It Matters
Shows **overall system stress**. High load average indicates the system is struggling to keep up with demand. This can be caused by CPU contention, memory pressure, or I/O bottlenecks.

---

## Graph 7: CPU Frequency
**Location**: Third row, right panel  
**Title**: "CPU Frequency (Higher is Better)"

### What It Shows
- **Purple line**: CPU frequency in MHz over time

### What to Look For
✅ **Good**:
- CPU frequency maintains high levels (near maximum)
- Frequency doesn't drop significantly under load
- CPU is not throttling due to thermal or power limits

⚠️ **Concerning**:
- CPU frequency drops significantly when workloads start
- Frequency throttling (drops to low MHz)
- CPU is being power-limited or thermal-throttled

### Why It Matters
Shows whether the CPU is **maintaining performance** or being throttled. If CPU frequency drops under load, it may indicate:
- Thermal throttling (CPU too hot)
- Power limits (not enough power)
- Performance degradation

---

## How to Read the Graphs Together

### Understanding Phase Transitions

All graphs have **colored phase backgrounds**:
- **Green**: BASELINE phase
- **Orange**: TRANSITION phase  
- **Red**: CONTENDED phase
- **Blue**: RECOVERY phase

Watch how metrics change as you move through phases:

1. **BASELINE → TRANSITION**:
   - Memory availability: Should stay stable
   - CPU usage: Should increase (LLM starting)
   - Swap: Should stay low
   - Load: Should increase

2. **TRANSITION → CONTENDED**:
   - Memory availability: **Critical** - should remain stable (QoS test)
   - Swap: Should NOT increase
   - CPU: May increase further
   - I/O: Should show activity

3. **CONTENDED → RECOVERY**:
   - Memory availability: Should recover toward baseline
   - CPU: Should decrease
   - Load: Should decrease
   - All metrics: Should return toward baseline

### Key Relationships

**Memory Availability + Swap Usage**:
- If memory availability drops AND swap increases → Memory starvation
- If memory availability stays stable AND swap stays low → QoS working

**CPU Usage + CPU Frequency**:
- If CPU usage high AND frequency high → Normal operation
- If CPU usage high AND frequency drops → Throttling issue
- If CPU usage drops AND memory pressure → May indicate blocking

**I/O Bandwidth + System Load**:
- High I/O + High load → System is busy (expected)
- Low I/O + High load → May indicate I/O blocking
- I/O spikes → May indicate memory-related I/O operations

---

## Quick Reference: What Each Graph Tells You

| Graph | Primary Purpose | Key Indicator |
|-------|----------------|----------------|
| **Memory Availability** | QoS effectiveness | Should stay stable |
| **Memory Usage Breakdown** | Memory allocation | Used vs cached patterns |
| **Swap Usage** | Memory pressure | Should stay <5% |
| **CPU Usage** | CPU activity | Stability matters |
| **I/O Bandwidth** | Resource sharing | Fair distribution |
| **System Load** | Overall stress | Manageable levels |
| **CPU Frequency** | Performance maintenance | Should stay high |
| **Memory Retention by Phase** | QoS summary | ≥95% target |
| **Phase Comparison Table** | Statistical summary | Easy comparison |

---

## Interpreting Results

### Excellent QoS Performance (All Graphs)

✅ **Memory Availability**: Stable line, no drops  
✅ **Swap Usage**: <1%, no spikes  
✅ **CPU Usage**: Stable, no blocking  
✅ **I/O Bandwidth**: Active, fair sharing  
✅ **System Load**: Manageable  
✅ **CPU Frequency**: Maintains high levels  
✅ **Memory Retention**: ≥95% in CONTENDED phase

### Poor QoS Performance (Warning Signs)

⚠️ **Memory Availability**: Drops significantly in CONTENDED  
⚠️ **Swap Usage**: Increases >5%  
⚠️ **CPU Usage**: Drops suddenly (blocking)  
⚠️ **I/O Bandwidth**: Drops to near zero  
⚠️ **System Load**: Extremely high  
⚠️ **CPU Frequency**: Throttles down  
⚠️ **Memory Retention**: <85% in CONTENDED phase

---

*This comprehensive visualization provides a complete picture of system behavior and QoS effectiveness across all phases of the test.*

