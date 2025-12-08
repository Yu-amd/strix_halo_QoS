#!/usr/bin/env python3
"""
Comprehensive Memory QoS Visualization
Shows detailed memory bandwidth protection analysis
"""

import sys
import os
from pathlib import Path

# Check for virtual environment
SCRIPT_DIR = Path(__file__).parent.resolve()
VENV_PATH = SCRIPT_DIR.parent / "venv"
if VENV_PATH.exists() and (VENV_PATH / "bin" / "python").exists():
    venv_python = str(VENV_PATH / "bin" / "python")
    if sys.executable != venv_python:
        os.execv(venv_python, [venv_python] + sys.argv)

import csv
import argparse
import os
from datetime import datetime

try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import matplotlib.dates as mdates
    import seaborn as sns
    HAS_MATPLOTLIB = True
except ImportError:
    HAS_MATPLOTLIB = False
    print("Warning: matplotlib not installed. Install with: pip install matplotlib seaborn")

if HAS_MATPLOTLIB:
    sns.set_style("whitegrid")
    plt.rcParams['figure.figsize'] = (20, 14)
    plt.rcParams['font.size'] = 10


def load_metrics(csv_file):
    """Load comprehensive metrics from CSV file"""
    timestamps = []
    phases = []
    cpu_percent = []
    memory_percent = []
    memory_available = []
    memory_used = []
    memory_cached = []
    memory_buffers = []
    swap_used = []
    swap_percent = []
    io_read = []
    io_write = []
    cpu_freq = []
    load_avg_1m = []
    load_avg_5m = []
    load_avg_15m = []
    context_switches = []
    interrupts = []
    cpu_user = []
    cpu_system = []
    
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                timestamps.append(datetime.fromisoformat(row['timestamp']))
                phases.append(row['phase'])
                cpu_percent.append(float(row['cpu_percent']))
                memory_percent.append(float(row['memory_percent']))
                memory_available.append(float(row['memory_available_gb']))
                memory_used.append(float(row['memory_used_gb']))
                memory_cached.append(float(row['memory_cached_gb']))
                memory_buffers.append(float(row['memory_buffers_gb']))
                swap_used.append(float(row['swap_used_gb']))
                swap_percent.append(float(row['swap_percent']))
                io_read.append(float(row['io_read_mb_s']))
                io_write.append(float(row['io_write_mb_s']))
                cpu_freq.append(float(row['cpu_freq_mhz']))
                load_avg_1m.append(float(row['load_avg_1m']))
                load_avg_5m.append(float(row['load_avg_5m']))
                load_avg_15m.append(float(row['load_avg_15m']))
                context_switches.append(int(row['context_switches']))
                interrupts.append(int(row['interrupts']))
                cpu_user.append(float(row['cpu_user']))
                cpu_system.append(float(row['cpu_system']))
            except (ValueError, KeyError) as e:
                continue
    
    return {
        'timestamps': timestamps,
        'phases': phases,
        'cpu_percent': cpu_percent,
        'memory_percent': memory_percent,
        'memory_available': memory_available,
        'memory_used': memory_used,
        'memory_cached': memory_cached,
        'memory_buffers': memory_buffers,
        'swap_used': swap_used,
        'swap_percent': swap_percent,
        'io_read': io_read,
        'io_write': io_write,
        'cpu_freq': cpu_freq,
        'load_avg_1m': load_avg_1m,
        'load_avg_5m': load_avg_5m,
        'load_avg_15m': load_avg_15m,
        'context_switches': context_switches,
        'interrupts': interrupts,
        'cpu_user': cpu_user,
        'cpu_system': cpu_system
    }


def calculate_phase_statistics(metrics):
    """Calculate statistics for each phase"""
    phases = ['baseline', 'transition', 'contended', 'recovery']
    stats = {}
    
    for phase in phases:
        phase_indices = [i for i, p in enumerate(metrics['phases']) if p == phase]
        if not phase_indices:
            continue
        
        phase_mem = [metrics['memory_available'][i] for i in phase_indices]
        phase_cpu = [metrics['cpu_percent'][i] for i in phase_indices]
        phase_swap = [metrics['swap_percent'][i] for i in phase_indices]
        
        stats[phase] = {
            'memory_avg': sum(phase_mem) / len(phase_mem) if phase_mem else 0,
            'memory_min': min(phase_mem) if phase_mem else 0,
            'memory_max': max(phase_mem) if phase_mem else 0,
            'memory_std': (sum((x - sum(phase_mem)/len(phase_mem))**2 for x in phase_mem) / len(phase_mem))**0.5 if phase_mem else 0,
            'cpu_avg': sum(phase_cpu) / len(phase_cpu) if phase_cpu else 0,
            'swap_avg': sum(phase_swap) / len(phase_swap) if phase_swap else 0,
            'samples': len(phase_indices)
        }
    
    return stats


def plot_comprehensive_metrics(metrics, output_file):
    """Create comprehensive visualization"""
    if not HAS_MATPLOTLIB:
        print("matplotlib not available")
        return
    
    timestamps = metrics['timestamps']
    
    # Create figure with subplots - increased height and spacing to prevent overlap
    fig = plt.figure(figsize=(22, 22))
    gs = fig.add_gridspec(5, 3, hspace=0.55, wspace=0.3)
    
    # Color map for phases
    phase_colors = {
        'baseline': '#2ecc71',      # Green
        'transition': '#f39c12',    # Orange
        'contended': '#e74c3c',     # Red
        'recovery': '#3498db'       # Blue
    }
    
    # Add phase background shading
    def add_phase_background(ax):
        current_phase = None
        phase_start = None
        for i, (ts, phase) in enumerate(zip(timestamps, metrics['phases'])):
            if phase != current_phase:
                if current_phase and phase_start is not None:
                    ax.axvspan(phase_start, ts, alpha=0.1, color=phase_colors.get(current_phase, 'gray'))
                current_phase = phase
                phase_start = ts
        if current_phase and phase_start:
            ax.axvspan(phase_start, timestamps[-1], alpha=0.1, color=phase_colors.get(current_phase, 'gray'))
    
    # 1. Memory Availability (Primary QoS Metric)
    ax1 = fig.add_subplot(gs[0, :])
    ax1.plot(timestamps, metrics['memory_available'], 'g-', linewidth=2.5, label='Available Memory', zorder=3)
    add_phase_background(ax1)
    ax1.set_xlabel('Time', fontsize=12)
    ax1.set_ylabel('Memory Available (GB)', fontsize=12)
    ax1.set_title('Memory Availability - Key QoS Metric\n(Higher is Better, Should Remain Stable)', 
                  fontsize=14, fontweight='bold')
    ax1.legend(fontsize=11)
    ax1.grid(True, alpha=0.3)
    ax1.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
    plt.setp(ax1.xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    # Add phase labels
    phase_positions = {}
    for phase in ['baseline', 'transition', 'contended', 'recovery']:
        phase_indices = [i for i, p in enumerate(metrics['phases']) if p == phase]
        if phase_indices:
            mid_idx = phase_indices[len(phase_indices)//2]
            phase_positions[phase] = timestamps[mid_idx]
    
    for phase, pos in phase_positions.items():
        ax1.text(pos, ax1.get_ylim()[1] * 0.95, phase.upper(), 
                ha='center', fontsize=10, fontweight='bold',
                bbox=dict(boxstyle='round,pad=0.5', facecolor=phase_colors.get(phase, 'gray'), alpha=0.3))
    
    # 2. Memory Usage Breakdown
    ax2 = fig.add_subplot(gs[1, 0])
    ax2.plot(timestamps, metrics['memory_used'], 'r-', linewidth=2, label='Used', alpha=0.8)
    ax2.plot(timestamps, metrics['memory_cached'], 'orange', linewidth=2, label='Cached', alpha=0.8)
    ax2.plot(timestamps, metrics['memory_buffers'], 'yellow', linewidth=2, label='Buffers', alpha=0.8)
    add_phase_background(ax2)
    ax2.set_xlabel('Time')
    ax2.set_ylabel('Memory (GB)')
    ax2.set_title('Memory Usage Breakdown\n(Lower is Better)', fontweight='bold')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    ax2.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
    plt.setp(ax2.xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    # 3. Swap Usage (Should Stay Low)
    ax3 = fig.add_subplot(gs[1, 1])
    ax3.plot(timestamps, metrics['swap_percent'], 'purple', linewidth=2, label='Swap %')
    add_phase_background(ax3)
    ax3.axhline(y=5, color='r', linestyle='--', linewidth=1, label='Warning (5%)')
    ax3.set_xlabel('Time')
    ax3.set_ylabel('Swap Usage (%)')
    ax3.set_title('Swap Usage - Memory Pressure Indicator\n(Lower is Better)', fontweight='bold')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    ax3.set_ylim([0, max(10, max(metrics['swap_percent']) * 1.2)])
    ax3.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
    plt.setp(ax3.xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    # 4. CPU Usage
    ax4 = fig.add_subplot(gs[1, 2])
    ax4.plot(timestamps, metrics['cpu_percent'], 'b-', linewidth=2, label='CPU %')
    add_phase_background(ax4)
    ax4.set_xlabel('Time')
    ax4.set_ylabel('CPU Usage (%)')
    ax4.set_title('CPU Usage\n(Stability Matters)', fontweight='bold')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    ax4.set_ylim([0, 100])
    ax4.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
    plt.setp(ax4.xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    # 5. I/O Bandwidth
    ax5 = fig.add_subplot(gs[2, 0])
    ax5.plot(timestamps, metrics['io_read'], 'b-', linewidth=2, label='Read MB/s', alpha=0.8)
    ax5.plot(timestamps, metrics['io_write'], 'r-', linewidth=2, label='Write MB/s', alpha=0.8)
    add_phase_background(ax5)
    ax5.set_xlabel('Time')
    ax5.set_ylabel('I/O Bandwidth (MB/s)')
    ax5.set_title('I/O Bandwidth - Fair Sharing\n(Higher is Better)', fontweight='bold')
    ax5.legend()
    ax5.grid(True, alpha=0.3)
    ax5.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
    plt.setp(ax5.xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    # 6. System Load
    ax6 = fig.add_subplot(gs[2, 1])
    ax6.plot(timestamps, metrics['load_avg_1m'], 'g-', linewidth=2, label='1min', alpha=0.8)
    ax6.plot(timestamps, metrics['load_avg_5m'], 'orange', linewidth=2, label='5min', alpha=0.8)
    ax6.plot(timestamps, metrics['load_avg_15m'], 'r-', linewidth=2, label='15min', alpha=0.8)
    add_phase_background(ax6)
    ax6.set_xlabel('Time')
    ax6.set_ylabel('Load Average')
    ax6.set_title('System Load Average\n(Lower is Better)', fontweight='bold')
    ax6.legend()
    ax6.grid(True, alpha=0.3)
    ax6.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
    plt.setp(ax6.xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    # 7. CPU Frequency
    ax7 = fig.add_subplot(gs[2, 2])
    ax7.plot(timestamps, metrics['cpu_freq'], 'purple', linewidth=2, label='CPU Freq')
    add_phase_background(ax7)
    ax7.set_xlabel('Time')
    ax7.set_ylabel('CPU Frequency (MHz)')
    ax7.set_title('CPU Frequency\n(Higher is Better)', fontweight='bold')
    ax7.legend()
    ax7.grid(True, alpha=0.3)
    ax7.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
    plt.setp(ax7.xaxis.get_majorticklabels(), rotation=45, ha='right')
    
    # 8. Memory Retention by Phase (Key Metric)
    ax8 = fig.add_subplot(gs[3, :])
    stats = calculate_phase_statistics(metrics)
    
    phases_list = []
    retention_list = []
    colors_list = []
    
    if 'baseline' in stats and 'baseline' in stats:
        baseline_mem = stats['baseline']['memory_avg']
        for phase in ['baseline', 'transition', 'contended', 'recovery']:
            if phase in stats and baseline_mem > 0:
                phase_mem = stats[phase]['memory_avg']
                retention = (phase_mem / baseline_mem) * 100
                phases_list.append(phase.upper())
                retention_list.append(retention)
                colors_list.append(phase_colors.get(phase, 'gray'))
        
        bars = ax8.bar(phases_list, retention_list, color=colors_list, alpha=0.8, edgecolor='black', linewidth=1.5)
        ax8.axhline(y=95, color='#27ae60', linestyle='--', linewidth=2, label='Excellent (95%)')
        ax8.axhline(y=85, color='#e67e22', linestyle='--', linewidth=2, label='Good (85%)')
        ax8.set_ylabel('Memory Retention (%)', fontsize=12)
        ax8.set_title('Memory Retention by Phase - QoS Effectiveness\n(Higher is Better, Target: ≥95%)', 
                     fontsize=14, fontweight='bold')
        ax8.legend(fontsize=11)
        ax8.grid(True, alpha=0.3, axis='y')
        ax8.set_ylim([0, max(105, max(retention_list) * 1.1)])
        
        # Add value labels
        for bar, val in zip(bars, retention_list):
            height = bar.get_height()
            ax8.text(bar.get_x() + bar.get_width()/2., height,
                    f'{val:.1f}%',
                    ha='center', va='bottom', fontweight='bold', fontsize=12)
    
    # 9. Phase Comparison Table
    ax9 = fig.add_subplot(gs[4, :])
    ax9.axis('off')
    
    if stats:
        table_data = []
        table_data.append(['Phase', 'Memory Avg (GB)', 'Memory Min (GB)', 'Memory Retention (%)', 'CPU Avg (%)', 'Swap Avg (%)'])
        
        baseline_mem = stats.get('baseline', {}).get('memory_avg', 0)
        for phase in ['baseline', 'transition', 'contended', 'recovery']:
            if phase in stats:
                s = stats[phase]
                retention = (s['memory_avg'] / baseline_mem * 100) if baseline_mem > 0 else 0
                table_data.append([
                    phase.upper(),
                    f"{s['memory_avg']:.2f}",
                    f"{s['memory_min']:.2f}",
                    f"{retention:.1f}%",
                    f"{s['cpu_avg']:.1f}",
                    f"{s['swap_avg']:.2f}"
                ])
        
        table = ax9.table(cellText=table_data, loc='center', cellLoc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2)
        
        # Color header
        for i in range(len(table_data[0])):
            table[(0, i)].set_facecolor('#3498db')
            table[(0, i)].set_text_props(weight='bold', color='white')
        
        # Color phase rows
        for i, phase in enumerate(['baseline', 'transition', 'contended', 'recovery'], 1):
            if i < len(table_data):
                color = phase_colors.get(phase, 'white')
                for j in range(len(table_data[0])):
                    table[(i, j)].set_facecolor(color)
                    table[(i, j)].set_alpha(0.3)
        
        ax9.set_title('Phase Comparison Summary', fontsize=14, fontweight='bold', pad=30)
    
    plt.suptitle('Strix Halo Memory QoS: Preventing CPU Memory Starvation Under AI Workloads', 
                 fontsize=18, fontweight='bold', y=0.998)
    
    plt.savefig(output_file, dpi=150, bbox_inches='tight', pad_inches=0.2)
    print(f"Saved visualization to: {output_file}")


def main():
    parser = argparse.ArgumentParser(description='Visualize comprehensive memory QoS metrics')
    parser.add_argument('--metrics-file', required=True, help='CSV file with metrics')
    parser.add_argument('--output', help='Output image file (default: auto-generated)')
    parser.add_argument('--html', action='store_true', help='Generate HTML report')
    args = parser.parse_args()
    
    if not HAS_MATPLOTLIB:
        print("Error: matplotlib and seaborn are required")
        return 1
    
    metrics_file = Path(args.metrics_file)
    if not metrics_file.exists():
        print(f"Error: Metrics file not found: {metrics_file}")
        return 1
    
    print(f"Loading metrics from: {metrics_file}")
    metrics = load_metrics(metrics_file)
    
    if not metrics['timestamps']:
        print("Error: No valid metrics found")
        return 1
    
    print(f"Loaded {len(metrics['timestamps'])} data points")
    
    # Calculate statistics
    stats = calculate_phase_statistics(metrics)
    
    print("\n=== Phase Statistics ===")
    baseline_mem = stats.get('baseline', {}).get('memory_avg', 0)
    for phase in ['baseline', 'transition', 'contended', 'recovery']:
        if phase in stats:
            s = stats[phase]
            retention = (s['memory_avg'] / baseline_mem * 100) if baseline_mem > 0 else 0
            print(f"\n{phase.upper()}:")
            print(f"  Memory Average: {s['memory_avg']:.2f} GB")
            print(f"  Memory Min: {s['memory_min']:.2f} GB")
            print(f"  Memory Retention: {retention:.1f}%")
            print(f"  CPU Average: {s['cpu_avg']:.1f}%")
            print(f"  Swap Average: {s['swap_avg']:.2f}%")
    
    # Generate visualization
    if args.output:
        output_file = Path(args.output)
    else:
        output_file = metrics_file.parent / f"memory_qos_comprehensive_{metrics_file.stem}.png"
    
    print(f"\nGenerating comprehensive visualization...")
    plot_comprehensive_metrics(metrics, output_file)
    
    print(f"\n✓ Visualization complete!")
    
    # Calculate overall assessment
    if baseline_mem > 0:
        contended_retention = (stats.get('contended', {}).get('memory_avg', 0) / baseline_mem * 100)
        print(f"\n=== Overall Assessment ===")
        print(f"Memory Retention (Contended vs Baseline): {contended_retention:.1f}%")
        if contended_retention >= 95:
            print("✓ EXCELLENT: No memory starvation detected. QoS is working perfectly.")
        elif contended_retention >= 85:
            print("✓ GOOD: Minimal memory impact. QoS is providing protection.")
        else:
            print("⚠ NEEDS ATTENTION: Some memory pressure observed.")
    
    return 0


if __name__ == '__main__':
    exit(main())

