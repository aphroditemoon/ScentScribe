#!/usr/bin/env python3
"""
ScentScribe ML Inference Server
Lightweight Flask API that serves predictions from the trained sklearn model.
This can run on the same server as the Node.js backend, or separately.

Endpoints:
  POST /predict        → fragrance-weather compatibility score
  POST /predict/batch  → multiple predictions at once
  POST /layering       → layering compatibility score
  GET  /health         → server status
"""

from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
import json
import os
from functools import wraps

app = Flask(__name__)


FAMILIES = ['fresh', 'oriental', 'woody', 'floral', 'aquatic',
            'gourmand', 'fougere', 'chypre', 'green', 'powdery']

TIMES_OF_DAY = ['morning', 'afternoon', 'evening', 'night']
SEASONS = ['spring', 'summer', 'autumn', 'winter']
SKIN_TYPES = ['dry', 'normal', 'oily', 'combination']


MODEL_PATH = os.path.join(os.path.dirname(__file__), 'scent_compatibility_model.pkl')
model = None
model_meta = {}

def load_model():
    global model, model_meta
    try:
        model = joblib.load(MODEL_PATH)
        meta_path = MODEL_PATH.replace('.pkl', '_meta.json')
        if os.path.exists(meta_path):
            with open(meta_path) as f:
                model_meta = json.load(f)
        print(f'✅ Model loaded: {MODEL_PATH}')
        return True
    except Exception as e:
        print(f'❌ Failed to load model: {e}')
        return False


def build_features_single(family: str, temperature: float, humidity: float,
                           time_of_day: str, season: str,
                           skin_type: str = 'normal',
                           base_notes: int = 3,
                           heart_notes: int = 3) -> np.ndarray:
    features = []


    features.append(np.clip(temperature, 0, 50) / 50.0)
    features.append(np.clip(humidity, 0, 100) / 100.0)
    features.append(np.clip(base_notes, 0, 6) / 6.0)
    features.append(np.clip(heart_notes, 0, 6) / 6.0)


    for val, categories in [
        (family.lower(), FAMILIES),
        (time_of_day.lower(), TIMES_OF_DAY),
        (season.lower(), SEASONS),
        (skin_type.lower(), SKIN_TYPES),
    ]:
        ohe = [1.0 if c == val else 0.0 for c in categories]
        features.extend(ohe)

    return np.array(features).reshape(1, -1)


API_KEY = os.environ.get('ML_API_KEY', 'scentscribe_ml_key')

def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('X-API-Key')
        if key != API_KEY:
            return jsonify({'error': 'Unauthorized'}), 401
        return f(*args, **kwargs)
    return decorated


@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'ok',
        'model_loaded': model is not None,
        'service': 'ScentScribe ML Server',
        'version': '1.0.0',
        'features': model_meta.get('feature_count', 28),
    })

@app.route('/predict', methods=['POST'])
@require_api_key
def predict():
    """Predict compatibility score for a single perfume + conditions."""
    data = request.get_json(force=True)

    required = ['family', 'temperature', 'humidity', 'time_of_day', 'season']
    missing = [k for k in required if k not in data]
    if missing:
        return jsonify({'error': f'Missing fields: {missing}'}), 400

    if model is None:
        return jsonify({'error': 'Model not loaded'}), 503

    try:
        X = build_features_single(
            family=data['family'],
            temperature=float(data['temperature']),
            humidity=float(data['humidity']),
            time_of_day=data['time_of_day'],
            season=data['season'],
            skin_type=data.get('skin_type', 'normal'),
            base_notes=int(data.get('base_note_count', 3)),
            heart_notes=int(data.get('heart_note_count', 3)),
        )
        score = float(np.clip(model.predict(X)[0], 0, 100))

        return jsonify({
            'score': round(score, 2),
            'grade': _grade(score),
            'recommendation': _recommendation(score, data['family'],
                                               float(data['temperature'])),
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/predict/batch', methods=['POST'])
@require_api_key
def predict_batch():
    """Predict compatibility for multiple perfumes at once."""
    data = request.get_json(force=True)
    items = data.get('items', [])

    if not items:
        return jsonify({'error': 'No items provided'}), 400

    if model is None:
        return jsonify({'error': 'Model not loaded'}), 503

    results = []
    for item in items:
        try:
            X = build_features_single(
                family=item['family'],
                temperature=float(data.get('temperature', 28)),
                humidity=float(data.get('humidity', 65)),
                time_of_day=data.get('time_of_day', 'afternoon'),
                season=data.get('season', 'summer'),
                skin_type=data.get('skin_type', 'normal'),
                base_notes=int(item.get('base_note_count', 3)),
                heart_notes=int(item.get('heart_note_count', 3)),
            )
            score = float(np.clip(model.predict(X)[0], 0, 100))
            results.append({
                'perfume_id': item.get('id'),
                'family': item['family'],
                'score': round(score, 2),
                'grade': _grade(score),
            })
        except Exception as e:
            results.append({
                'perfume_id': item.get('id'),
                'error': str(e),
                'score': 50.0,
            })

    results.sort(key=lambda x: x.get('score', 0), reverse=True)
    return jsonify({'predictions': results, 'count': len(results)})

@app.route('/layering', methods=['POST'])
@require_api_key
def layering_compatibility():
    """Predict layering compatibility between 2–3 perfumes."""
    data = request.get_json(force=True)
    families = data.get('families', [])

    if len(families) < 2:
        return jsonify({'error': 'Provide at least 2 families'}), 400


    compat_matrix = {
        frozenset(['fresh', 'aquatic']): 0.95,
        frozenset(['fresh', 'floral']): 0.90,
        frozenset(['fresh', 'green']): 0.92,
        frozenset(['oriental', 'woody']): 0.95,
        frozenset(['oriental', 'gourmand']): 0.85,
        frozenset(['woody', 'chypre']): 0.88,
        frozenset(['floral', 'chypre']): 0.87,
        frozenset(['floral', 'woody']): 0.82,
        frozenset(['gourmand', 'oriental']): 0.85,
        frozenset(['fresh', 'oriental']): 0.55,
        frozenset(['aquatic', 'gourmand']): 0.40,
        frozenset(['powdery', 'floral']): 0.85,
        frozenset(['fougere', 'fresh']): 0.88,
    }

    score = 100.0
    for i in range(len(families) - 1):
        for j in range(i + 1, len(families)):
            key = frozenset([families[i].lower(), families[j].lower()])
            compat = compat_matrix.get(key, 0.72)
            score *= compat

    score = float(np.clip(score, 0, 100))

    return jsonify({
        'compatibility_score': round(score, 2),
        'grade': _grade(score),
        'families': families,
        'interpretation': _layering_interpretation(score),
    })

@app.route('/model/info', methods=['GET'])
def model_info():
    return jsonify({
        'meta': model_meta,
        'families': FAMILIES,
        'times_of_day': TIMES_OF_DAY,
        'seasons': SEASONS,
        'skin_types': SKIN_TYPES,
    })


def _grade(score: float) -> str:
    if score >= 85: return 'A'
    if score >= 70: return 'B'
    if score >= 55: return 'C'
    if score >= 40: return 'D'
    return 'F'

def _recommendation(score: float, family: str, temp: float) -> str:
    if score >= 85:
        return f'Excellent match! {family.capitalize()} will perform beautifully at {temp:.0f}°C.'
    if score >= 65:
        return f'Good match for today\'s conditions. Apply {family} to pulse points.'
    if score >= 45:
        return f'Moderate fit. Use lightly or consider waiting for better conditions.'
    return f'Not ideal today. Consider a different family for {temp:.0f}°C.'

def _layering_interpretation(score: float) -> str:
    if score >= 85: return 'Exceptional harmony — these scents were made for each other.'
    if score >= 70: return 'Good compatibility — apply heavier scent first, let settle 2-3 min.'
    if score >= 50: return 'Mixed — use very sparingly, test on skin before committing.'
    return 'Challenging pairing — the scent profiles may clash on your skin.'


if __name__ == '__main__':
    load_model()
    port = int(os.environ.get('ML_PORT', 5001))
    print(f'🌸 ScentScribe ML Server starting on port {port}')
    app.run(host='0.0.0.0', port=port, debug=False)
