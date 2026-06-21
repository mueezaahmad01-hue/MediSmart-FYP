from flask import Flask, request, jsonify
import pickle
import pandas as pd
import re

app = Flask(__name__)

model = pickle.load(open("model/model.pkl", "rb"))
vectorizer = pickle.load(open("model/vectorizer.pkl", "rb"))

data = pd.read_csv("model/cleaned_medicine_dataset.csv")


def clean_text(text):
    text = str(text).lower()
    text = re.sub(r"\(.*?\)", "", text)
    text = re.sub(r"[^a-zA-Z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


data["name_clean"] = data["name"].apply(clean_text)
data["target_salt"] = data["target_salt"].apply(clean_text)

BRAND_SALT_MAP = {
    "panadol": "paracetamol",
    "panadol extra": "paracetamol",
    "calpol": "paracetamol",
    "glucophage": "metformin",
    "metfor": "metformin",
    "brufen": "ibuprofen",
    "advil": "ibuprofen",
    "augmentin": "amoxycillin clavulanic acid",
    "amoxil": "amoxycillin",
    "zyrtec": "cetirizine",
    "rigix": "cetirizine",
    "azithral": "azithromycin",
    "allegra": "fexofenadine",
    "biforge": "amlodipine (as besylate) and valsartan",
    "extor": "amlodipine (as besylate) and valsartan",
    "zopent": "pantoprazole sodium sesquihydrate",
    "protium": "pantoprazole sodium sesquihydrate",

}


def find_salt_from_dataset(medicine_name):
    cleaned = clean_text(medicine_name)

    if cleaned in BRAND_SALT_MAP:
        return BRAND_SALT_MAP[cleaned], cleaned, "brand_map"

    exact_match = data[
        data["name_clean"].str.contains(cleaned, na=False, regex=False)
    ]

    if not exact_match.empty:
        row = exact_match.iloc[0]
        return row["target_salt"], row["name"], "dataset_match"

    token = cleaned.split()[0] if cleaned else ""

    if len(token) >= 4:
        token_match = data[
            data["name_clean"].str.contains(
                rf"\b{re.escape(token)}\b",
                na=False,
                regex=True,
            )
        ]

        if not token_match.empty:
            row = token_match.iloc[0]
            return row["target_salt"], row["name"], "token_match"

    return None, None, None


def predict_salt_with_model(medicine_name):
    cleaned = clean_text(medicine_name)
    vector = vectorizer.transform([cleaned])

    probabilities = model.predict_proba(vector)[0]
    max_prob = probabilities.max()
    predicted_class = model.classes_[probabilities.argmax()]
    confidence_percent = round(max_prob * 100, 2)

    if confidence_percent < 45:
        return None, confidence_percent

    return predicted_class, confidence_percent


def get_alternatives(salt, matched_name):
    alternatives_df = data[
        data["target_salt"].str.lower() == salt.lower()
    ].copy()

    if alternatives_df.empty:
        return []

    matched_clean = clean_text(matched_name)

    alternatives_df = alternatives_df[
        alternatives_df["name_clean"] != matched_clean
    ]

    return (
        alternatives_df["name"]
        .drop_duplicates()
        .head(8)
        .tolist()
    )


@app.route("/")
def home():
    return "MediSmart AI API is running"


@app.route("/predict", methods=["POST"])
def predict():
    try:
        body = request.get_json()
        medicine_name = body.get("medicine", "")

        if not medicine_name:
            return jsonify({"error": "Medicine name is required"}), 400

        salt, matched_name, method = find_salt_from_dataset(medicine_name)
        confidence = None

        if salt is None:
            salt, confidence = predict_salt_with_model(medicine_name)

            if salt is not None:
                matched_name = medicine_name
                method = "ml_model_prediction"

        if salt is None:
            return jsonify({
                "input_medicine": medicine_name,
                "matched_name": None,
                "predicted_salt": None,
                "method": "no_match_found",
                "alternatives": [],
                "confidence": confidence if confidence else 0
            })

        alternatives = get_alternatives(salt, matched_name)

        return jsonify({
            "input_medicine": medicine_name,
            "matched_name": matched_name,
            "predicted_salt": salt,
            "method": method,
            "alternatives": alternatives,
            "confidence": confidence if confidence else 95
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)