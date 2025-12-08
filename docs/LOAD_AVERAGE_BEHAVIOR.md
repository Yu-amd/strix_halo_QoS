# Why Load Average Lines Behave This Way

## The Question

**Why does the 1-minute line go up faster than the 5-minute line, which goes up faster than the 15-minute line?**
**Why do all three lines increase in all phases?**

## The Answer: Moving Averages with Different Time Windows

Load average is a **moving average** - it averages data over a time window. The three lines use different time windows, which causes them to respond at different speeds.

### How Moving Averages Work

Think of it like this:

**1-Minute Load Average**:
- Averages data from the **last 1 minute**
- Very responsive to recent changes
- Drops old data quickly

**5-Minute Load Average**:
- Averages data from the **last 5 minutes**
- Includes the 1-minute data PLUS 4 more minutes of older data
- More stable, slower to change

**15-Minute Load Average**:
- Averages data from the **last 15 minutes**
- Includes the 5-minute data PLUS 10 more minutes of older data
- Most stable, slowest to change

### Visual Example

Imagine you're measuring load over time:

```
Time:  0:00  0:01  0:02  0:03  0:04  0:05  0:06  0:07  0:08  0:09  0:10
Load:  1.0   1.0   1.0   5.0   5.0   5.0   5.0   5.0   5.0   5.0   5.0
       ^baseline starts^     ^workload starts^
```

**At 0:03 (workload just started)**:
- 1-minute average: Averages [1.0, 1.0, 5.0] = **2.3** (responds quickly)
- 5-minute average: Averages [1.0, 1.0, 1.0, 5.0, 5.0] = **2.6** (includes older low values)
- 15-minute average: Averages [1.0, 1.0, 1.0, 5.0, 5.0, ...] = **~1.5** (includes many old low values)

**At 0:10 (workload running for 7 minutes)**:
- 1-minute average: Averages [5.0, 5.0, 5.0, ...] = **5.0** (fully reflects current load)
- 5-minute average: Averages [5.0, 5.0, 5.0, 5.0, 5.0] = **5.0** (fully reflects current load)
- 15-minute average: Averages [1.0, 1.0, 1.0, 5.0, 5.0, 5.0, ...] = **~3.5** (still includes old baseline data)

## Why 1-Min > 5-Min > 15-Min (Rate of Increase)

### The Math

When load increases, each average responds differently:

**1-Minute Average**:
- Only looks at last 1 minute
- Old low values drop out quickly
- **Responds immediately** to new high values

**5-Minute Average**:
- Looks at last 5 minutes
- Includes 4 minutes of older (potentially lower) data
- **Responds more slowly** - takes time for old low values to drop out

**15-Minute Average**:
- Looks at last 15 minutes
- Includes 14 minutes of older (potentially lower) data
- **Responds very slowly** - takes longest for old low values to drop out

### Example Calculation

**Baseline Phase** (load = 2.0):
- 1-min: 2.0
- 5-min: 2.0
- 15-min: 2.0

**Workload Starts** (load jumps to 8.0):

**After 1 minute**:
- 1-min: Averages [2.0, 8.0] = **5.0** (50% new, 50% old)
- 5-min: Averages [2.0, 2.0, 2.0, 2.0, 8.0] = **3.2** (20% new, 80% old)
- 15-min: Averages [2.0, 2.0, ..., 8.0] = **~2.4** (6.7% new, 93.3% old)

**After 5 minutes**:
- 1-min: **8.0** (fully reflects new load)
- 5-min: Averages [2.0, 8.0, 8.0, 8.0, 8.0] = **6.8** (80% new, 20% old)
- 15-min: Averages [2.0, 2.0, ..., 8.0, 8.0, ...] = **~3.7** (33% new, 67% old)

**After 15 minutes**:
- 1-min: **8.0** (fully reflects new load)
- 5-min: **8.0** (fully reflects new load)
- 15-min: **8.0** (fully reflects new load - all old data dropped out)

## Why All Three Lines Increase in All Phases

### The Cumulative Effect

Load average is **cumulative** - it includes historical data. Even when entering a new phase, the longer averages still include data from previous phases.

### Phase-by-Phase Explanation

**BASELINE Phase** (first 20% of test):
- Workload starts, load increases
- 1-min: Responds quickly → increases
- 5-min: Responds slowly → increases gradually
- 15-min: Responds very slowly → increases very gradually

**TRANSITION Phase** (next 30%):
- LLM starts, load increases further
- 1-min: Responds quickly to new increase → increases faster
- 5-min: Still includes some baseline data, but new high values added → increases
- 15-min: Still includes baseline data, but new values added → increases slowly

**CONTENDED Phase** (next 30%):
- Both workloads fully active, load at maximum
- 1-min: Fully reflects current high load → may stabilize or continue increasing
- 5-min: Baseline data finally dropping out, high load data accumulating → increases
- 15-min: Baseline data still present, but high load data accumulating → increases

**RECOVERY Phase** (last 20%):
- LLM stops, load decreases
- 1-min: Responds quickly to decrease → may decrease
- 5-min: Still includes high load data from CONTENDED → may still increase or stabilize
- 15-min: Still includes baseline and high load data → may still increase

### Why They All Increase

1. **1-Minute Line**: 
   - Always reflects recent activity
   - Increases when activity increases
   - Decreases when activity decreases

2. **5-Minute Line**:
   - Includes last 5 minutes
   - As new high-load data enters, old low-load data exits
   - **Net effect**: Increases as more high-load data accumulates

3. **15-Minute Line**:
   - Includes last 15 minutes
   - As new high-load data enters, very old low-load data exits
   - **Net effect**: Increases slowly as high-load data accumulates

## Visual Timeline Example

```
Time:    0:00    0:05    0:10    0:15    0:20    0:30    0:45    1:00
Phase:   BASE    BASE    TRANS   TRANS   CONT    CONT    RECOV   RECOV
Load:    2.0     3.0     5.0     6.0     8.0     8.0     4.0     3.0
         ^workload^      ^LLM^            ^both^         ^LLM stops^

1-min:   2.0 → 3.0 → 5.0 → 6.0 → 8.0 → 8.0 → 4.0 → 3.0
         (responds immediately to each change)

5-min:   2.0 → 2.5 → 3.5 → 4.5 → 6.0 → 7.0 → 6.5 → 5.0
         (includes 4 min of older data, responds slower)

15-min:  2.0 → 2.1 → 2.5 → 3.0 → 4.0 → 5.0 → 5.5 → 5.0
         (includes 14 min of older data, responds very slowly)
```

Notice:
- **1-min line**: Follows current load closely
- **5-min line**: Lags behind, smoother
- **15-min line**: Lags most, smoothest

## This is Normal and Expected!

### Why This Happens

1. **Different Time Windows**: Each line averages over a different period
2. **Cumulative Data**: Longer averages include more historical data
3. **Gradual Response**: Longer averages take time to "catch up" to current conditions

### What It Means

**All three lines increasing** means:
- System load is increasing over time
- Each average is incorporating the new higher load values
- This is **expected** as workloads start and intensify

**1-min increasing faster than 5-min, which increases faster than 15-min** means:
- Current activity is higher than historical average
- The system is getting busier
- Longer averages are "catching up" to current conditions

## When to Be Concerned

### Normal Pattern (What You're Seeing)
✅ All three lines increase as workloads start
✅ 1-min increases fastest (most responsive)
✅ 5-min increases slower (smoother)
✅ 15-min increases slowest (smoothest)
✅ Lines eventually converge when load stabilizes

### Concerning Pattern
⚠️ 1-min line spikes extremely high (>10x cores)
⚠️ 1-min much higher than 15-min (huge gap = recent spike)
⚠️ Lines don't converge (load keeps increasing)
⚠️ 15-min line doesn't increase at all (system may be stuck)

## In Your Results

If you see:
- **1-min line**: Increases quickly in each phase
- **5-min line**: Increases more slowly, smoother
- **15-min line**: Increases slowest, smoothest
- **All three**: Increase throughout the test

**This is completely normal!** It means:
1. System load is increasing as workloads start (expected)
2. The moving averages are working as designed
3. Each line reflects its time window correctly
4. The system is responding to the workloads

The key is to look at the **final values** and whether they're **manageable** (not extreme overload).

---

*This behavior is a fundamental property of moving averages - shorter windows respond faster, longer windows are smoother but lag behind.*

