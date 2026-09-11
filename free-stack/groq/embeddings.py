"""
Groq API - Embeddings Example
Generate vector embeddings for RAG, search, and similarity.
"""

import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))


def get_embedding(text: str, model: str = "nomic-embed-text-v1.5") -> list:
    """Get embedding vector for text."""
    response = client.embeddings.create(
        model=model,
        input=text,
    )
    return response.data[0].embedding


def get_embeddings(texts: list, model: str = "nomic-embed-text-v1.5") -> list:
    """Get embeddings for multiple texts."""
    response = client.embeddings.create(
        model=model,
        input=texts,
    )
    return [item.embedding for item in response.data]


def cosine_similarity(a: list, b: list) -> float:
    """Calculate cosine similarity between two vectors."""
    dot_product = sum(x * y for x, y in zip(a, b))
    norm_a = sum(x * x for x in a) ** 0.5
    norm_b = sum(x * x for x in b) ** 0.5
    return dot_product / (norm_a * norm_b)


if __name__ == "__main__":
    print("=== Groq Embeddings ===\n")

    # Single embedding
    text = "The quick brown fox jumps over the lazy dog"
    embedding = get_embedding(text)
    print(f"Text: {text}")
    print(f"Embedding dimensions: {len(embedding)}")
    print(f"First 5 values: {embedding[:5]}\n")

    # Similarity search
    documents = [
        "Python is a programming language",
        "JavaScript runs in browsers",
        "Machine learning uses neural networks",
        "The cat sat on the mat",
    ]

    query = "artificial intelligence"
    query_embedding = get_embedding(query)

    doc_embeddings = get_embeddings(documents)

    print(f"Query: {query}")
    print("\nSimilarity scores:")
    for doc, doc_emb in zip(documents, doc_embeddings):
        score = cosine_similarity(query_embedding, doc_emb)
        print(f"  {score:.4f} - {doc}")
