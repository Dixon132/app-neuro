import sys
sys.path.insert(0, '.')
from app.services.eeg_processor import EEGProcessor
from app.services.ml_predictor import MLPredictor
import numpy as np

proc = EEGProcessor()
predictor = MLPredictor()

files = {
    'chb01_10 (CHB-MIT)': 'data/uploads/1781056496.952325_chb01_10.edf',
    'Subject23_2 (A)': 'data/uploads/1780113846.145204_Subject23_2.edf',
    'Subject23_2 (B)': 'data/uploads/1780112389.961199_Subject23_2.edf',
    'Subject23_2 (C)': 'data/uploads/1780109183.210152_Subject23_2.edf',
    'SC4002E0-PSG (Sleep)': 'data/uploads/1780108690.671205_SC4002E0-PSG.edf',
    'eeg_test_sample (CSV)': 'eeg_test_sample.csv',
}

print("=" * 80)
print("TESTING MODEL WITH AVAILABLE FILES")
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

for r in results:
    print(f"  {r['name']:30s} -> Risk: {r['risk']:5.1f}%, Confidence: {r['confidence']:.2f}, Label: {r['label']}")

print("\n" + "=" * 80)
