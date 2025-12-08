# Understanding System Load Average (Graph 6)

## What is Load Average?

**Load Average** represents the average number of processes that are:
1. **Running** - Currently using CPU
2. **Runnable** - Ready to run but waiting for CPU time
3. **Waiting for I/O** - Blocked waiting for disk/network operations

It's a measure of how "busy" your system is, not just CPU usage.

## The Three Lines Explained

Graph 6 shows three load average values:

### 1. **1-Minute Load Average** (Green line)
- Average over the **last 1 minute**
- Most responsive to current conditions
- Shows immediate system stress

### 2. **5-Minute Load Average** (Orange line)
- Average over the **last 5 minutes**
- Smoothed out, less reactive to spikes
- Shows recent trend

### 3. **15-Minute Load Average** (Red line)
- Average over the **last 15 minutes**
- Most stable, slowest to change
- Shows longer-term trend

## How to Interpret Load Average Values

### Understanding the Numbers

**Load average is relative to your CPU cores:**

- **Load of 1.0** on a **1-core system** = CPU is fully utilized
- **Load of 2.0** on a **2-core system** = CPU is fully utilized
- **Load of 4.0** on a **4-core system** = CPU is fully utilized

**General rule**: Load average should ideally be **≤ number of CPU cores**

### Examples

**System with 8 CPU cores:**
- Load of 2.0 = Light load (25% utilization)
- Load of 4.0 = Moderate load (50% utilization)
- Load of 8.0 = Heavy load (100% utilization)
- Load of 16.0 = Overloaded (200% - processes waiting)

**System with 24 CPU cores:**
- Load of 5.0 = Light load
- Load of 12.0 = Moderate load
- Load of 24.0 = Heavy load
- Load of 48.0 = Overloaded

## What the Graph Shows

### Normal Pattern (Good QoS)

**Baseline Phase**:
- Load increases as memory workload starts
- Example: Load goes from 1.0 → 3.0 (workload is active)

**Transition Phase**:
- Load increases further as LLM starts
- Example: Load goes from 3.0 → 6.0 (both workloads active)

**Contended Phase**:
- Load stabilizes at higher level
- Example: Load stays around 6.0-8.0 (sustained load)
- **Key**: Load is manageable, not extreme

**Recovery Phase**:
- Load decreases as LLM stops
- Example: Load drops from 8.0 → 4.0 → 2.0
- System recovers

### Concerning Patterns

**Extreme Load**:
- Load > 10x number of CPU cores
- Example: Load of 50+ on 8-core system
- Indicates severe overload

**Load Not Decreasing**:
- Load stays high in RECOVERY phase
- Indicates processes stuck or system struggling

**1-Minute Much Higher Than 15-Minute**:
- Recent spike in activity
- May indicate sudden stress

## Relationship to Other Metrics

### Load Average + CPU Usage

**High Load + High CPU Usage**:
- Normal - system is busy
- Many processes using CPU
- Expected under load

**High Load + Low CPU Usage**:
- Processes waiting for I/O
- May indicate I/O bottleneck
- Could be memory-related (waiting for memory access)

**Low Load + High CPU Usage**:
- Few processes, but CPU-intensive
- Normal for single-threaded workloads

### Load Average + Memory

**High Load + Memory Pressure**:
- Processes may be waiting for memory
- Could indicate memory starvation
- Check swap usage (Graph 3)

**High Load + Stable Memory**:
- System is busy but memory is available
- Normal operation
- QoS is working

### Load Average + I/O

**High Load + High I/O**:
- System is busy with I/O operations
- Normal for I/O-intensive workloads

**High Load + Low I/O**:
- Processes may be blocked
- Could indicate I/O bottleneck
- Or processes waiting for other resources

## What Load Average Tells You About QoS

### With Good QoS (Expected)

✅ **Load increases** when workloads start (expected)
✅ **Load is manageable** (not extreme)
✅ **Load decreases** when workloads stop
✅ **Load reflects actual work** being done

**Example on 24-core system**:
- Baseline: Load 5.0 (workload active)
- Contended: Load 12.0 (both workloads active)
- Recovery: Load 6.0 (one workload)
- **Interpretation**: System is busy but not overloaded

### Without QoS (Hypothetical)

❌ **Load becomes extreme** (>10x cores)
❌ **Load doesn't decrease** when workloads stop
❌ **Load spikes** indicate system struggling
❌ **Processes stuck** waiting for resources

**Example on 24-core system**:
- Baseline: Load 5.0
- Contended: Load 50.0+ (extreme overload)
- Recovery: Load 30.0 (still high, slow recovery)
- **Interpretation**: System is severely overloaded, processes waiting

## Reading the Three Lines Together

### Normal Pattern

```
1-minute (green):  [spiky, responsive]
5-minute (orange): [smoother, trend]
15-minute (red):   [smoothest, baseline]
```

**What this means**:
- 1-minute shows current activity (may spike)
- 5-minute shows recent trend
- 15-minute shows longer-term average

### Concerning Pattern

```
1-minute (green):  [very high spike]
5-minute (orange): [increasing]
15-minute (red):   [also increasing]
```

**What this means**:
- Recent spike in activity
- Trend is increasing
- System may be struggling

### Recovery Pattern

```
1-minute (green):  [drops quickly]
5-minute (orange): [drops slowly]
15-minute (red):   [drops very slowly]
```

**What this means**:
- Immediate activity decreased
- Recent trend improving
- Long-term average still reflects past load

## Practical Examples

### Example 1: 24-Core System, Good QoS

**Baseline Phase**:
- 1-min: 3.0
- 5-min: 2.5
- 15-min: 2.0
- **Interpretation**: Light load, workload just started

**Contended Phase**:
- 1-min: 8.0
- 5-min: 6.5
- 15-min: 4.0
- **Interpretation**: Moderate load, both workloads active, manageable

**Recovery Phase**:
- 1-min: 4.0
- 5-min: 5.0
- 15-min: 5.5
- **Interpretation**: Load decreasing, system recovering

### Example 2: 24-Core System, Poor QoS (Hypothetical)

**Baseline Phase**:
- 1-min: 3.0
- 5-min: 2.5
- 15-min: 2.0

**Contended Phase**:
- 1-min: 45.0
- 5-min: 35.0
- 15-min: 20.0
- **Interpretation**: **EXTREME OVERLOAD** - processes waiting, system struggling

**Recovery Phase**:
- 1-min: 30.0
- 5-min: 32.0
- 15-min: 25.0
- **Interpretation**: Load not decreasing, processes stuck

## Key Takeaways

1. **Load Average = System Busyness**
   - Not just CPU usage
   - Includes processes waiting for CPU, I/O, etc.

2. **Relative to CPU Cores**
   - Load of 8.0 on 8-core system = fully utilized
   - Load of 8.0 on 24-core system = light load

3. **Three Time Windows**
   - 1-minute: Current activity (responsive)
   - 5-minute: Recent trend (smoothed)
   - 15-minute: Long-term average (baseline)

4. **Good QoS Pattern**
   - Load increases with workloads (expected)
   - Load is manageable (not extreme)
   - Load decreases when workloads stop

5. **Watch for**
   - Extreme load (>10x cores)
   - Load not decreasing
   - 1-minute much higher than 15-minute (spike)

## In Context of Memory QoS

**Load Average helps you understand**:
- Is the system overloaded?
- Are processes waiting (high load + low CPU)?
- Is the system recovering properly?
- Is there a bottleneck somewhere?

**Combined with other graphs**:
- **High load + stable memory** = System busy but memory QoS working
- **High load + memory pressure** = May indicate memory-related issues
- **High load + low CPU** = Processes may be blocked waiting for resources

---

*Load average is a system-wide metric that helps you understand overall system stress and whether processes are getting the resources they need.*

