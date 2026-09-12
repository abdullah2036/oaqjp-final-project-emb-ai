#!/usr/bin/env bash
# Run this INSIDE the Skills Network Cloud IDE, from the cloned repo root
# (the folder that already contains templates/ and static/).
set -e

if [ ! -d templates ]; then
  echo "ERROR: run this from the cloned repo root (no templates/ folder here)." >&2
  exit 1
fi

mkdir -p EmotionDetection

cat > EmotionDetection/emotion_detection.py <<'EOF_7072'
"""Emotion detection module backed by the embedded Watson NLP EmotionPredict service."""

import json
import requests

URL = ('https://sn-watson-emotion.labs.skills.network/v1/'
       'watson.runtime.nlp.v1/NlpService/EmotionPredict')
HEADERS = {"grpc-metadata-mm-model-id": "emotion_aggregated-workflow_lang_en_stock"}


def emotion_detector(text_to_analyze):
    """Run emotion detection on the given text.

    Sends the text to the Watson NLP EmotionPredict endpoint and returns the
    scores for anger, disgust, fear, joy and sadness together with the
    dominant emotion. If the service responds with status code 400 (for
    example a blank input), every value in the returned dictionary is None.

    Args:
        text_to_analyze (str): The statement whose emotion must be detected.

    Returns:
        dict: Emotion scores plus the key 'dominant_emotion'.
    """
    input_json = {"raw_document": {"text": text_to_analyze}}
    response = requests.post(URL, json=input_json, headers=HEADERS)

    if response.status_code == 400:
        return {
            'anger': None,
            'disgust': None,
            'fear': None,
            'joy': None,
            'sadness': None,
            'dominant_emotion': None
        }

    formatted_response = json.loads(response.text)
    emotions = formatted_response['emotionPredictions'][0]['emotion']

    anger_score = emotions['anger']
    disgust_score = emotions['disgust']
    fear_score = emotions['fear']
    joy_score = emotions['joy']
    sadness_score = emotions['sadness']

    scores = {
        'anger': anger_score,
        'disgust': disgust_score,
        'fear': fear_score,
        'joy': joy_score,
        'sadness': sadness_score
    }
    dominant_emotion = max(scores, key=scores.get)

    return {
        'anger': anger_score,
        'disgust': disgust_score,
        'fear': fear_score,
        'joy': joy_score,
        'sadness': sadness_score,
        'dominant_emotion': dominant_emotion
    }
EOF_7072

cat > EmotionDetection/__init__.py <<'EOF_20128'
"""EmotionDetection package exposing the emotion_detector function."""

from . import emotion_detection
from .emotion_detection import emotion_detector
EOF_20128

cat > server.py <<'EOF_46975'
"""Flask web server that exposes the EmotionDetection application.

Run this module to serve the emotion detection interface on localhost:5000.
"""

from flask import Flask, render_template, request
from EmotionDetection.emotion_detection import emotion_detector

app = Flask("Emotion Detector")


@app.route("/emotionDetector")
def emot_detector():
    """Analyse the text supplied by the user and return a formatted response.

    Reads the 'textToAnalyze' query parameter, runs emotion detection on it
    and builds the sentence shown in the interface. When the dominant emotion
    is None the input was invalid and an error message is returned instead.

    Returns:
        str: The formatted system response or an error message.
    """
    text_to_analyze = request.args.get('textToAnalyze')
    response = emotion_detector(text_to_analyze)

    if response['dominant_emotion'] is None:
        return "Invalid text! Please try again!"

    return (
        "For the given statement, the system response is "
        f"'anger': {response['anger']}, "
        f"'disgust': {response['disgust']}, "
        f"'fear': {response['fear']}, "
        f"'joy': {response['joy']} and "
        f"'sadness': {response['sadness']}. "
        f"The dominant emotion is {response['dominant_emotion']}."
    )


@app.route("/")
def render_index_page():
    """Render the landing page of the application.

    Returns:
        str: The rendered index.html template.
    """
    return render_template('index.html')


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF_46975

cat > test_emotion_detection.py <<'EOF_33962'
"""Unit tests for the emotion_detector function of the EmotionDetection package."""

import unittest
from EmotionDetection.emotion_detection import emotion_detector


class TestEmotionDetector(unittest.TestCase):
    """Test the dominant emotion returned for a set of known statements."""

    def test_emotion_detector(self):
        """Check that each statement maps to the expected dominant emotion."""
        result_joy = emotion_detector('I am glad this happened')
        self.assertEqual(result_joy['dominant_emotion'], 'joy')

        result_anger = emotion_detector('I am really mad about this')
        self.assertEqual(result_anger['dominant_emotion'], 'anger')

        result_disgust = emotion_detector('I feel disgusted just hearing about this')
        self.assertEqual(result_disgust['dominant_emotion'], 'disgust')

        result_sadness = emotion_detector('I am so sad about this')
        self.assertEqual(result_sadness['dominant_emotion'], 'sadness')

        result_fear = emotion_detector('I am really afraid that this will happen')
        self.assertEqual(result_fear['dominant_emotion'], 'fear')


if __name__ == '__main__':
    unittest.main()
EOF_33962

cat > README.md <<'EOF_95072'
# Final project

Emotion Detection web application built with the embeddable Watson NLP libraries
and deployed with Flask.

## Structure

```
final_project/
├── EmotionDetection/
│   ├── __init__.py
│   └── emotion_detection.py
├── static/
│   └── mywebscript.js
├── templates/
│   └── index.html
├── server.py
├── test_emotion_detection.py
└── README.md
```

## Run

```
python3 server.py
```

Then open http://localhost:5000
EOF_95072

echo
echo "Files written:"
find . -name '*.py' -not -path './.git/*' | sort
echo
echo "Next:"
echo "  python3 -m pip install requests flask pylint"
echo "  python3 test_emotion_detection.py"
echo "  python3 -m pylint server.py"
echo "  python3 server.py"
