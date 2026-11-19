from typing import Optional
from sentence_transformers import SentenceTransformer
from app.core.config import settings

class EmbeddingService:
    _instance: Optional["EmbeddingService"] = None
    _model: Optional[SentenceTransformer] = None

    @classmethod
    def get_instance(cls) -> "EmbeddingService":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def get_model(self) -> SentenceTransformer:
        if self._model is None:
            print(f"[EmbeddingService] Loading SentenceTransformer: {settings.EMBEDDING_MODEL_NAME}...")
            self._model = SentenceTransformer(settings.EMBEDDING_MODEL_NAME)
        return self._model

    def encode_text(self, text: str) -> list[float]:
        model = self.get_model()
        vector = model.encode(text.strip(), normalize_embeddings=True)
        return [float(x) for x in vector]

    def encode_texts(self, texts: list[str]) -> list[list[float]]:
        model = self.get_model()
        vectors = model.encode(texts, normalize_embeddings=True)
        return [[float(x) for x in v] for v in vectors]

embedding_service = EmbeddingService.get_instance()
