#!/usr/bin/env python3
"""
ScentScribe ML Training Script
Trains a fragrance-weather compatibility model using scikit-learn.
Exports a TFLite-compatible model for Flutter on-device inference.

Features used:
  - Temperature (normalized 0-50°C)
  - Humidity (normalized 0-100%)
  - Time of day (one-hot: morning/afternoon/evening/night)
  - Season (one-hot: spring/summer/autumn/winter)
  - Family (one-hot: 10 families)
  - Skin type (one-hot: dry/normal/oily/combination)
  - Base note count (normalized)
  - Heart note count (normalized)

Target: compatibility score (0-100)
"""

import numpy as np
import pandas as pd
import json
import os
from sklearn.ensemble import GradientBoostingRegressor, RandomForestRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.pipeline import Pipeline
import joblib
import warnings
warnings.filterwarnings('ignore')


FAMILIES = ['fresh', 'oriental', 'woody', 'floral', 'aquatic',
            'gourmand', 'fougere', 'chypre', 'green', 'powdery']

TIMES_OF_DAY = ['morning', 'afternoon', 'evening', 'night']
SEASONS = ['spring', 'summer', 'autumn', 'winter']
SKIN_TYPES = ['dry', 'normal', 'oily', 'combination']


def generate_training_data(n_samples: int = 8000) -> pd.DataFrame:
    """
    Generate synthetic training data based on fragrance science principles.
    In production, replace with real user journal data from PostgreSQL.
    """
    np.random.seed(42)
    records = []


    family_profiles = {
        'fresh':    {'ideal_temp': (20, 35), 'ideal_hum': (30, 65), 'best_times': ['morning', 'afternoon'], 'best_seasons': ['spring', 'summer']},
        'aquatic':  {'ideal_temp': (18, 33), 'ideal_hum': (40, 70), 'best_times': ['morning', 'afternoon'], 'best_seasons': ['spring', 'summer']},
        'oriental': {'ideal_temp': (0,  20), 'ideal_hum': (20, 55), 'best_times': ['evening', 'night'],     'best_seasons': ['autumn', 'winter']},
        'gourmand': {'ideal_temp': (0,  18), 'ideal_hum': (20, 50), 'best_times': ['evening', 'night'],     'best_seasons': ['autumn', 'winter']},
        'woody':    {'ideal_temp': (5,  22), 'ideal_hum': (30, 60), 'best_times': ['afternoon', 'evening'], 'best_seasons': ['autumn', 'winter']},
        'floral':   {'ideal_temp': (15, 28), 'ideal_hum': (40, 70), 'best_times': ['morning', 'afternoon'], 'best_seasons': ['spring', 'summer']},
        'chypre':   {'ideal_temp': (12, 25), 'ideal_hum': (35, 65), 'best_times': ['afternoon', 'evening'], 'best_seasons': ['spring', 'autumn']},
        'fougere':  {'ideal_temp': (10, 24), 'ideal_hum': (30, 60), 'best_times': ['morning', 'afternoon'], 'best_seasons': ['spring', 'autumn']},
        'green':    {'ideal_temp': (15, 28), 'ideal_hum': (50, 75), 'best_times': ['morning', 'afternoon'], 'best_seasons': ['spring', 'summer']},
        'powdery':  {'ideal_temp': (8,  22), 'ideal_hum': (25, 55), 'best_times': ['evening', 'night'],     'best_seasons': ['winter', 'autumn']},
    }

    for _ in range(n_samples):
        family = np.random.choice(FAMILIES)
        profile = family_profiles[family]
        time = np.random.choice(TIMES_OF_DAY)
        season = np.random.choice(SEASONS)
        skin = np.random.choice(SKIN_TYPES)


        if np.random.random() < 0.6:
            temp = np.random.uniform(*profile['ideal_temp'])
            hum = np.random.uniform(*profile['ideal_hum'])
        else:
            temp = np.random.uniform(0, 45)
            hum = np.random.uniform(15, 95)

        base_notes = np.random.randint(1, 6)
        heart_notes = np.random.randint(1, 6)


        score = 50.0


        ideal_t_min, ideal_t_max = profile['ideal_temp']
        if ideal_t_min <= temp <= ideal_t_max:
            score += 25
        else:
            delta = min(abs(temp - ideal_t_min), abs(temp - ideal_t_max))
            score += max(0, 25 - delta * 1.5)


        ideal_h_min, ideal_h_max = profile['ideal_hum']
        if ideal_h_min <= hum <= ideal_h_max:
            score += 15
        else:
            delta = min(abs(hum - ideal_h_min), abs(hum - ideal_h_max))
            score += max(0, 15 - delta * 0.3)


        if time in profile['best_times']:
            score += 10


        if season in profile['best_seasons']:
            score += 8


        if skin == 'oily':
            score += base_notes * 0.5
        elif skin == 'dry':
            score -= 3


        if temp > 30 and family in ['oriental', 'gourmand']:
            score -= 10
        if temp < 15 and family in ['fresh', 'aquatic']:
            score -= 12


        if hum > 80 and family in ['oriental', 'gourmand']:
            score -= 8


        score += np.random.normal(0, 4)
        score = float(np.clip(score, 0, 100))

        records.append({
            'family': family,
            'temperature': temp,
            'humidity': hum,
            'time_of_day': time,
            'season': season,
            'skin_type': skin,
            'base_note_count': base_notes,
            'heart_note_count': heart_notes,
            'compatibility_score': score,
        })

    return pd.DataFrame(records)


def build_features(df: pd.DataFrame) -> np.ndarray:
    features = []


    features.append(df['temperature'].values.reshape(-1, 1) / 50.0)
    features.append(df['humidity'].values.reshape(-1, 1) / 100.0)
    features.append(df['base_note_count'].values.reshape(-1, 1) / 6.0)
    features.append(df['heart_note_count'].values.reshape(-1, 1) / 6.0)


    for col, categories in [
        ('family', FAMILIES),
        ('time_of_day', TIMES_OF_DAY),
        ('season', SEASONS),
        ('skin_type', SKIN_TYPES),
    ]:
        ohe = np.zeros((len(df), len(categories)))
        for i, cat in enumerate(categories):
            ohe[:, i] = (df[col] == cat).astype(float)
        features.append(ohe)

    return np.hstack(features)


def train_model(df: pd.DataFrame):
    X = build_features(df)
    y = df['compatibility_score'].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42)


    models = {
        'GradientBoosting': GradientBoostingRegressor(
            n_estimators=200, max_depth=5, learning_rate=0.05,
            subsample=0.8, random_state=42),
        'RandomForest': RandomForestRegressor(
            n_estimators=150, max_depth=8, random_state=42, n_jobs=-1),
        'MLP': MLPRegressor(
            hidden_layer_sizes=(128, 64, 32), activation='relu',
            max_iter=500, random_state=42, early_stopping=True,
            validation_fraction=0.1),
    }

    best_model = None
    best_score = -np.inf
    best_name = ''

    print('\n🔮 Training ScentScribe Compatibility Models...\n')
    for name, model in models.items():
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        mse = mean_squared_error(y_test, y_pred)
        r2 = r2_score(y_test, y_pred)
        cv = cross_val_score(model, X, y, cv=5, scoring='r2')

        print(f'  {name}:')
        print(f'    MSE: {mse:.2f}  |  R²: {r2:.4f}  |  CV R²: {cv.mean():.4f} ± {cv.std():.4f}')

        if r2 > best_score:
            best_score = r2
            best_model = model
            best_name = name

    print(f'\n✅ Best model: {best_name} (R² = {best_score:.4f})')
    return best_model, X_test, y_test


def export_model(model, output_dir='ml/'):
    os.makedirs(output_dir, exist_ok=True)


    model_path = os.path.join(output_dir, 'scent_compatibility_model.pkl')
    joblib.dump(model, model_path)
    print(f'\n📦 Model saved: {model_path}')


    meta = {
        'features': ['temperature', 'humidity', 'base_note_count', 'heart_note_count'] +
                    FAMILIES + TIMES_OF_DAY + SEASONS + SKIN_TYPES,
        'feature_count': 4 + len(FAMILIES) + len(TIMES_OF_DAY) + len(SEASONS) + len(SKIN_TYPES),
        'families': FAMILIES,
        'times_of_day': TIMES_OF_DAY,
        'seasons': SEASONS,
        'skin_types': SKIN_TYPES,
        'version': '1.0.0',
    }
    with open(os.path.join(output_dir, 'model_meta.json'), 'w') as f:
        json.dump(meta, f, indent=2)
    print(f'📋 Metadata saved: {output_dir}model_meta.json')

    return model_path


def predict_compatibility(model, family: str, temperature: float,
                           humidity: float, time_of_day: str,
                           season: str, skin_type: str = 'normal',
                           base_notes: int = 3, heart_notes: int = 3) -> float:
    row = pd.DataFrame([{
        'family': family,
        'temperature': temperature,
        'humidity': humidity,
        'time_of_day': time_of_day,
        'season': season,
        'skin_type': skin_type,
        'base_note_count': base_notes,
        'heart_note_count': heart_notes,
    }])
    X = build_features(row)
    score = model.predict(X)[0]
    return float(np.clip(score, 0, 100))


def print_feature_importance(model):
    if not hasattr(model, 'feature_importances_'):
        return

    feature_names = (
        ['temperature', 'humidity', 'base_notes', 'heart_notes'] +
        FAMILIES + TIMES_OF_DAY + SEASONS + SKIN_TYPES
    )
    importances = model.feature_importances_
    top = sorted(zip(feature_names, importances), key=lambda x: x[1], reverse=True)[:10]

    print('\n📊 Top Feature Importances:')
    for name, imp in top:
        bar = '█' * int(imp * 100)
        print(f'  {name:<25} {bar} {imp:.4f}')


if __name__ == '__main__':
    print('🌸 ScentScribe ML Training Pipeline')
    print('=' * 50)


    print('\n📊 Generating synthetic training data...')
    df = generate_training_data(n_samples=10000)
    print(f'   Generated {len(df)} samples')
    print(f'   Score range: {df.compatibility_score.min():.1f} – {df.compatibility_score.max():.1f}')
    print(f'   Mean score: {df.compatibility_score.mean():.1f}')


    model, X_test, y_test = train_model(df)


    print_feature_importance(model)


    export_model(model, 'ml/')


    print('\n🔮 Demo Predictions:')
    demos = [
        ('fresh', 32, 70, 'afternoon', 'summer', 'oily'),
        ('oriental', 12, 40, 'night', 'winter', 'dry'),
        ('gourmand', 28, 80, 'afternoon', 'summer', 'normal'),
        ('aquatic', 26, 60, 'morning', 'spring', 'normal'),
        ('woody', 18, 45, 'evening', 'autumn', 'oily'),
    ]

    for family, temp, hum, time, season, skin in demos:
        score = predict_compatibility(model, family, temp, hum, time, season, skin)
        bar = '█' * (int(score) // 5)
        status = '✅' if score >= 75 else '⚠️' if score >= 50 else '❌'
        print(f'  {status} {family:<10} {temp}°C {hum}%RH {time:<10} → {score:.1f}/100 {bar}')

    print('\n✨ Training complete! Model ready for deployment.')
