import sys
sys.path.insert(0, '.')
from app.services.eeg_processor import EEGProcessor
from app.services.ml_predictor import MLPredictor
import numpy as np

proc = EEGProcessor()
predictor = MLPredictor()

# Test files
files = {
    'chb01_16 (seizure)': 'data/uploads/1778185399.401425_chb01_16.edf',
    'chb01_18 (seizure)': 'data/uploads/1778185455.606746_chb01_18.edf',
    'chb01_21 (seizure)': 'data/uploads/1778185385.065126_chb01_21.edf',
    'chb01_19 (normal)': 'data/uploads/1778185417.278038_chb01_19.edf',
    'chb01_20 (normal)': 'data/uploads/1778185445.147619_chb01_20.edf',
}

print("=" * 80)
print("TESTING NEW CALIBRATED MODEL")
print("=" * 80)

results = []
for name, path in files.items():
    try:
        print(f"\nProcessing: {name}")
        processed = proc.process_eeg(path)
        prediction = predictor.predict(processed)
        
        results.append({
            'name': name,
            'risk': prediction['risk_score'],
            'confidence': prediction['confidence'],
            'label': prediction['prediction'],
            'proba_normal': prediction['probabilities']['normal'],
            'proba_epileptic': prediction['probabilities']['epileptic'],
        })
        
        print(f"  Risk Score: {prediction['risk_score']:.1f}%")
        print(f"  Confidence: {prediction['confidence']:.2f}")
        print(f"  Label: {prediction['prediction']}")
        print(f"  Probabilities: Normal={prediction['probabilities']['normal']:.3f}, "
              f"Epileptic={prediction['probabilities']['epileptic']:.3f}")
        
    except Exception as e:
        print(f"  ERROR: {e}")
        import traceback
        traceback.print_exc()

print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)

seizure_results = [r for r in results if 'seizure' in r['name']]
normal_results = [r for r in results if 'normal' in r['name']]

if seizure_results:
    print("\nSEIZURE FILES:")
    for r in seizure_results:
        print(f"  {r['name']:25s} → Risk: {r['risk']:5.1f}%, Confidence: {r['confidence']:.2f}, Label: {r['label']}")
    avg_risk = np.mean([r['risk'] for r in seizure_results])
    print(f"  Average Risk: {avg_risk:.1f}%")

if normal_results:
    print("\nNORMAL FILES:")
    for r in normal_results:
        print(f"  {r['name']:25s} → Risk: {r['risk']:5.1f}%, Confidence: {r['confidence']:.2f}, Label: {r['label']}")
    avg_risk = np.mean([r['risk'] for r in normal_results])
    print(f"  Average Risk: {avg_risk:.1f}%")

print("\n" + "=" * 80)
print("EVALUATION")
print("=" * 80)

# Check if model is working correctly
seizure_risks = [r['risk'] for r in seizure_results]
normal_risks = [r['risk'] for r in normal_results]

if seizure_risks and normal_risks:
    avg_seizure = np.mean(seizure_risks)
    avg_normal = np.mean(normal_risks)
    
    print(f"\nAverage Risk - Seizure: {avg_seizure:.1f}%, Normal: {avg_normal:.1f}%")
    print(f"Separation: {avg_seizure - avg_normal:.1f}%")
    
    if avg_seizure > avg_normal:
        print("✓ Model correctly identifies seizures as higher risk")
    else:
        print("✗ Model is confused - seizures should have higher risk")
    
    # Check for extreme predictions
    all_risks = seizure_risks + normal_risks
    if any(r >= 95 for r in all_risks):
        print("⚠ Warning: Some predictions are too confident (≥95%)")
    elif any(r <= 5 for r in all_risks):
        print("⚠ Warning: Some predictions are too confident (≤5%)")
    else:
        print("✓ Confidence levels are reasonable (no extreme predictions)")
