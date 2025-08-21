
# rideIt — Mobile Biker Behavior Recorder & Classifier

An iOS app that records inertial and location data from a rider's iPhone and classifies riding/driving behaviour using Core ML models. This repository contains the iOS app, exported Core ML models, and the training scripts and datasets used to build those models.


https://github.com/user-attachments/assets/febb9f44-d62f-4d15-92a9-4acea39b950b


## Quick summary

- Purpose: record IMU (accelerometer/gyroscope) and GPS traces while biking and classify segments into behaviour classes (e.g., normal ride, overtake, waiting, etc.).
- Platform: Swift + SwiftUI iOS app (Xcode project in `ApplicazioniMobiliProgetto`).
- ML: Core ML models are bundled with the app (see the `ApplicazioniMobiliProgetto` folder). Training scripts and raw/processed data are in the `rideIt` folder.

## What the app records

- Device inertial sensors: accelerometer and gyroscope via `MotionManager.swift`.
- Location/GPS via `LocationManager.swift`.
- The app aggregates readings into `RecordedPath` objects and stores sessions using `PersistenceController.swift`.
- UI surfaces: `MapView.swift`, `MiniMapView.swift`, `LogView.swift`, `PathListView.swift`, `SummaryView.swift`.

These components produce time-series feature windows that the ML models consume to predict rider behaviour.

## Where the ML models live

- App-bundled models (already integrated into the Xcode project):
	- `ApplicazioniMobiliProgetto/ClassifierCreateML.mlmodel`
	- `ApplicazioniMobiliProgetto/DrivingClassifierCreateML.mlmodel`
	- `ApplicazioniMobiliProgetto/DrivingClassifierCreateMLEuler.mlmodel`
	- `ApplicazioniMobiliProgetto/DrivingBehaviorClassifier.mlmodel` (in `rideIt/` as well)
	- `rideIt/DrivingBehaviorClassifierSMOTE.mlmodel`

These .mlmodel files are compiled by Xcode and used at runtime by the app to produce predictions from live sensor data.

## ML training pipeline (high level)

Files and scripts used for training are in the `rideIt/` folder:

- `concatenated_data.csv` — preprocessed dataset (time-series features and labels).
- `randomForest.py` / `randomForestSMORE.py` — example training scripts that build sklearn-based classifiers (Random Forest). They produce models locally.
- `createCoreMl.py` — converts trained models to Core ML format (using coremltools or Create ML export path that the app includes).

Typical pipeline steps:
1. Collect session data from the app and/or existing dataset.
2. Preprocess and extract features into `concatenated_data.csv` (windowing, statistics, Euler angle features, etc.).
3. Train a classifier (e.g., random forest) with `randomForest.py` and evaluate.
4. If needed, apply resampling (SMOTE) to fix class imbalance (`randomForestSMORE.py`).
5. Convert the final model to Core ML with `createCoreMl.py` or export from Create ML; add the `.mlmodel` file to the Xcode project.

## How to run the app (developer notes)

1. Open `ApplicazioniMobiliProgetto.xcworkspace` or `ApplicazioniMobiliProgetto.xcodeproj` in Xcode.
2. Select your device as a run target (recommended: a physical iPhone — real sensors needed). The Simulator doesn't provide real motion/GPS sensors.
3. Build and run. Grant Motion & Location permissions when prompted.

Tip: Run on-device to capture realistic IMU and GPS traces. Use the app UI to start/stop recordings and review detected events in `LogView`/`SummaryView`.

## How to retrain models (developer commands)

Assumptions: Python 3.8+, and common ML packages. You can create a virtualenv and install required packages. Example packages likely needed: numpy, pandas, scikit-learn, imbalanced-learn, coremltools (if converting to .mlmodel).

Example (macOS / zsh):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install numpy pandas scikit-learn imbalanced-learn coremltools
# Train a model (this depends on the script arguments implemented):
python3 rideIt/randomForest.py
# Optionally run SMOTE-enabled training
python3 rideIt/randomForestSMORE.py
# Convert to Core ML
python3 rideIt/createCoreMl.py
```

If your scripts require additional arguments or data paths, open them and follow the function-level docstrings or prints.

## Notes on integration

- Place the resulting `.mlmodel` file in `ApplicazioniMobiliProgetto/` and add it to the Xcode target. Xcode will compile it into a `.mlmodelc` and generate Swift classes you can use.
- Prediction should run on-device and be invoked where the app processes windows of IMU/GPS features (look for model usage points in the repository).
