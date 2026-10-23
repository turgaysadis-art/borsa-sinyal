# ==========================================
# BORSA SİNYAL BACKEND - MAKİNE ÖĞRENMESİ MODELİ
# ==========================================
from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing: Optional

import joblib
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_score, recall_score
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier

from backend.config import get_settings
from backend.nlp.text_processor import get_processor

logger = logging.getLogger(__name__)


class SignalModel:
    """TF-IDF + XGBoost tabanlı sinyal tahmin modeli."""
    
    def __init__(self):
        settings = get_settings()
        self.model_path = Path(settings.model_path)
        self.vectorizer_path = Path(settings.vectorizer_path)
        self.model_version = settings.model_version
        self.min_samples = settings.min_training_samples
        
        self.pipeline: Optional[XGBClassifier] = None
        self.vectorizer: Optional[TfidfVectorizer] = None
        self.processor = get_processor()
        self.is_trained = False
        
        self.model_path.parent.mkdir(parents=True, exist_ok=True)
    
    def prepare_features(self, texts: List[str]) -> np.ndarray:
        """Metinleri TF-IDF vektörlerine çevir."""
        processed_texts = [self.processor.process(text) for text in texts]
        if self.vectorizer is None:
            raise ValueError("Vectorizer not fitted. Train the model first.")
        return self.vectorizer.transform(processed_texts)
    
    def train(
        self,
        texts: List[str],
        labels: List[str],
        test_size: float = 0.2,
        random_state: int = 42,
    ) -> dict:
        """
        Modeli eğit.
        labels: "UP", "DOWN", "FLAT" string'leri
        """
        if len(texts) < self.min_samples:
            raise ValueError(f"Yetersiz eğitim verisi: {len(texts)} < {self.min_samples}")
        
        logger.info(f"Training model with {len(texts)} samples...")
        
        # Label encoding
        label_map = {"DOWN": 0, "FLAT": 1, "UP": 2}
        y = np.array([label_map.get(l, 1) for l in labels])
        
        # Metinleri işle
        processed_texts = [self.processor.process(text) for text in texts]
        
        # TF-IDF Vectorizer
        self.vectorizer = TfidfVectorizer(
            max_features=5000,
            ngram_range=(1, 2),
            min_df=2,
            max_df=0.95,
            sublinear_tf=True,
        )
        
        X = self.vectorizer.fit_transform(processed_texts)
        
        # Train/Test split
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state, stratify=y
        )
        
        # XGBoost Classifier
        self.pipeline = XGBClassifier(
            n_estimators=200,
            max_depth=6,
            learning_rate=0.1,
            subsample=0.8,
            colsample_bytree=0.8,
            random_state=random_state,
            n_jobs=-1,
            eval_metric="mlogloss",
            verbosity=0,
        )
        
        self.pipeline.fit(X_train, y_train)
        
        # Değerlendirme
        y_pred = self.pipeline.predict(X_test)
        
        metrics = {
            "accuracy": float(accuracy_score(y_test, y_pred)),
            "precision": float(precision_score(y_test, y_pred, average="weighted", zero_division=0)),
            "recall": float(recall_score(y_test, y_pred, average="weighted", zero_division=0)),
            "f1_score": float(f1_score(y_test, y_pred, average="weighted", zero_division=0)),
            "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
            "training_samples": len(texts),
            "feature_count": X.shape[1],
            "model_version": self.model_version,
            "last_trained_at": datetime.now(timezone.utc).isoformat(),
        }
        
        self.is_trained = True
        logger.info(f"Training completed. Accuracy: {metrics['accuracy']:.4f}")
        
        # Kaydet
        self.save()
        
        return metrics
    
    def predict(self, texts: List[str]) -> List[dict]:
        """Tahmin yap."""
        if not self.is_trained or self.pipeline is None:
            self.load()
        
        if not self.is_trained:
            raise ValueError("Model not trained yet.")
        
        X = self.prepare_features(texts)
        probas = self.pipeline.predict_proba(X)
        preds = self.pipeline.predict(X)
        
        label_map = {0: "DOWN", 1: "FLAT", 2: "UP"}
        results = []
        
        for i, pred in enumerate(preds):
            proba = probas[i]
            results.append({
                "direction": label_map[pred],
                "confidence": float(proba[pred]),
                "probabilities": {
                    "DOWN": float(proba[0]),
                    "FLAT": float(proba[1]),
                    "UP": float(proba[2]),
                },
            })
        
        return results
    
    def predict_single(self, text: str) -> dict:
        return self.predict([text])[0]
    
    def save(self) -> None:
        """Modeli ve vectorizer'ı kaydet."""
        if self.pipeline is not None:
            joblib.dump(self.pipeline, self.model_path)
        if self.vectorizer is not None:
            joblib.dump(self.vectorizer, self.vectorizer_path)
        
        # Metadata
        meta_path = self.model_path.with_suffix(".json")
        meta = {
            "model_version": self.model_version,
            "saved_at": datetime.now(timezone.utc).isoformat(),
            "is_trained": self.is_trained,
        }
        with open(meta_path, "w", encoding="utf-8") as f:
            json.dump(meta, f, ensure_ascii=False, indent=2)
        
        logger.info(f"Model saved to {self.model_path}")
    
    def load(self) -> bool:
        """Kaydedilmiş modeli yükle."""
        try:
            if self.model_path.exists() and self.vectorizer_path.exists():
                self.pipeline = joblib.load(self.model_path)
                self.vectorizer = joblib.load(self.vectorizer_path)
                self.is_trained = True
                logger.info(f"Model loaded from {self.model_path}")
                return True
        except Exception as e:
            logger.warning(f"Failed to load model: {e}")
        return False
    
    def get_feature_importance(self, top_n: int = 20) -> List[tuple[str, float]]:
        """En önemli özellikleri (kelimeleri) getir."""
        if not self.is_trained or self.pipeline is None or self.vectorizer is None:
            return []
        
        feature_names = self.vectorizer.get_feature_names_out()
        importances = self.pipeline.feature_importances_
        
        indices = np.argsort(importances)[::-1][:top_n]
        return [(feature_names[i], float(importances[i])) for i in indices]


class SimpleRuleBasedModel:
    """Basit kural tabanlı model (fallback için)."""
    
    def __init__(self):
        self.analyzer = None
    
    def _get_analyzer(self):
        if self.analyzer is None:
            from backend.nlp.sentiment import SentimentAnalyzer
            self.analyzer = SentimentAnalyzer()
        return self.analyzer
    
    def predict(self, texts: List[str]) -> List[dict]:
        analyzer = self._get_analyzer()
        results = []
        
        for text in texts:
            detail = analyzer.analyze_detailed(text)
            score = detail["score"]
            
            if score > 0.1:
                direction = "UP"
                confidence = min(0.6 + score * 0.3, 0.85)
            elif score < -0.1:
                direction = "DOWN"
                confidence = min(0.6 + abs(score) * 0.3, 0.85)
            else:
                direction = "FLAT"
                confidence = 0.55
            
            results.append({
                "direction": direction,
                "confidence": confidence,
                "probabilities": {
                    "UP": (1 + score) / 2 if score > 0 else (1 + score) / 4,
                    "FLAT": 1 - abs(score) / 2,
                    "DOWN": (1 - score) / 2 if score < 0 else (1 - score) / 4,
                },
            })
        
        return results