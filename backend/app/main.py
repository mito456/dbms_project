from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1.endpoints import auth, publications, researchers, recommendations, meta

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Research Collaboration & Publication Intelligence System API featuring pgvector similarity search, collaborative intelligence, and conference matching.",
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Middleware for modern React frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for local dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API v1 Routers
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["Authentication"])
app.include_router(publications.router, prefix=f"{settings.API_V1_STR}/publications", tags=["Publications & Semantic Search"])
app.include_router(researchers.router, prefix=f"{settings.API_V1_STR}/researchers", tags=["Researchers & Profiles"])
app.include_router(recommendations.router, prefix=f"{settings.API_V1_STR}/recommendations", tags=["Recommendations"])
app.include_router(meta.router, prefix=f"{settings.API_V1_STR}/meta", tags=["Metadata & Analytics"])

@app.get("/")
def root():
    return RedirectResponse(url="/docs")

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
