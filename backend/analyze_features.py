import sys
sys.path.insert(0, '.')
from app.services.eeg_processor import EEGProcessor
import numpy as np

proc = EEGProcessor()

# Analyze all 5 files
files = {
    'chb01_16 (seizure)': 'data/uploads/1778185399.401425_chb01_16.edf',
    'chb01_18 (seizure)': 'data/uploads/1778185455.606746_chb01_18.edf',
    'chb01_21 (seizure)': 'data/uploads/1778185385.065126_chb01_21.edf',
    'chb01_19 (normal)': 'data/uploads/1778185417.278038_chb01_19.edf',
    'chb01_20 (normal)': 'data/uploads/1778185445.147619_chb01_20.edf',
}

print("=" * 80)
print("FEATURE ANALYSIS - SEIZURE vs NORMAL")
print("=" * 80)

all_results = {}
for name, path in files.items():
    try:
        result = proc.process_eeg(path)
        feats = result['features']['aggregated']
        all_results[name] = feats
        
        print(f"\n{name}")
        print("-" * 80)
        print(f"  mean_kurtosis:          {feats.get('mean_kurtosis', 0):.3f}")
        print(f"  mean_line_length:       {feats.get('mean_line_length', 0):.3f}")
        print(f"  mean_delta_rel:         {feats.get('mean_delta_rel', 0):.3f}")
        print(f"  mean_alpha_rel:         {feats.get('mean_alpha_rel', 0):.3f}")
        print(f"  mean_slow_fast_ratio:   {feats.get('mean_slow_fast_ratio', 0):.3f}")
        print(f"  mean_spectral_entropy:  {feats.get('mean_spectral_entropy', 0):.3f}")
        print(f"  mean_spike_rate_per_sec:{feats.get('mean_spike_rate_per_sec', 0):.3f}")
        print(f"  mean_dwt_d0_energy:     {feats.get('mean_dwt_d0_energy', 0):.3f}")
    except Exception as e:
        print(f"\n{name}: ERROR - {e}")

# Summary statistics
print("\n" + "=" * 80)
print("SUMMARY: SEIZURE vs NORMAL COMPARISON")
print("=" * 80)

seizure_files = [k for k in all_results.keys() if 'seizure' in k]
normal_files = [k for k in all_results.keys() if 'normal' in k]

key_features = [
    'mean_kurtosis', 'mean_line_length', 'mean_delta_rel', 
    'mean_alpha_rel', 'mean_slow_fast_ratio', 'mean_spectral_entropy',
    'mean_spike_rate_per_sec', 'mean_dwt_d0_energy'
]

for feat in key_features:
    seizure_vals = [all_results[k].get(feat, 0) for k in seizure_files]
    normal_vals = [all_results[k].get(feat, 0) for k in normal_files]
    
    if seizure_vals and normal_vals:
        print(f"\n{feat}:")
        print(f"  Seizure: mean={np.mean(seizure_vals):.3f}, std={np.std(seizure_vals):.3f}, range=[{np.min(seizure_vals):.3f}, {np.max(seizure_vals):.3f}]")
        print(f"  Normal:  mean={np.mean(normal_vals):.3f}, std={np.std(normal_vals):.3f}, range=[{np.min(normal_vals):.3f}, {np.max(normal_vals):.3f}]")
        print(f"  Separation: {abs(np.mean(seizure_vals) - np.mean(normal_vals)):.3f}")
