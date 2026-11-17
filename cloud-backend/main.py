import os
import firebase_admin
import httpx
from firebase_admin import auth
from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="RYZONE AI Text API", version="0.1.0")


def verified_user(authorization: str | None = Header(default=None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Firebase sign-in required")
    try:
        if not firebase_admin._apps:
            firebase_admin.initialize_app()
        return auth.verify_id_token(authorization[7:].strip(), check_revoked=True)
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid or expired sign-in token") from exc


class StoryInput(BaseModel):
    idea: str = Field(min_length=3, max_length=4000)
    language: str = Field(default="Tamil", max_length=40)
    genre: str = Field(default="Adventure", max_length=60)
    audience: str = Field(default="family", max_length=40)


class DialogueInput(BaseModel):
    scene: str = Field(min_length=3, max_length=3000)
    characters: str = Field(default="", max_length=2000)
    language: str = Field(default="Tamil", max_length=40)
    tone: str = Field(default="Funny", max_length=60)


class ScenesInput(BaseModel):
    story: str = Field(min_length=3, max_length=5000)
    language: str = Field(default="Tamil", max_length=40)
    sceneCount: int = Field(default=5, ge=3, le=10)


def make_prompt(task: str, data: BaseModel) -> str:
    d = data.model_dump()
    if task == "story":
        return f"Write an original family-friendly cartoon story in {d['language']}. Genre: {d['genre']}. Audience: {d['audience']}. Idea: {d['idea']}. Include a title, characters, beginning, middle, ending, and visual moments suitable for animation."
    if task == "dialogue":
        return f"Write natural character dialogue in {d['language']} for this scene: {d['scene']}. Characters: {d['characters'] or 'Create suitable fictional characters'}. Tone: {d['tone']}. Label each speaker and include brief acting/emotion cues."
    return f"Turn this story into exactly {d['sceneCount']} numbered cartoon storyboard scenes in {d['language']}: {d['story']}. For each scene include location, visual action, camera shot, character emotion, dialogue, and sound/music cue."


async def generate_text(prompt: str) -> str:
    base = os.getenv("AI_PROVIDER_BASE_URL", "").rstrip("/")
    key = os.getenv("AI_PROVIDER_API_KEY", "")
    model = os.getenv("AI_PROVIDER_MODEL", "")
    if not base or not key or not model:
        raise HTTPException(status_code=503, detail="AI text provider is not configured on the server yet")
    url = base if base.endswith("/chat/completions") else base + "/chat/completions"
    try:
        async with httpx.AsyncClient(timeout=90) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
                json={"model": model, "messages": [
                    {"role": "system", "content": "You are RYZONE, a creative and safe cartoon-film writer. Follow the requested language and format."},
                    {"role": "user", "content": prompt},
                ], "temperature": 0.8},
            )
            response.raise_for_status()
            payload = response.json()
            result = payload["choices"][0]["message"]["content"].strip()
            if not result:
                raise ValueError("Empty provider response")
            return result
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=502, detail="The AI provider request failed") from exc


@app.get("/health")
def health():
    return {"service": "ryzone-ai-text", "status": "ok", "provider_configured": bool(os.getenv("AI_PROVIDER_BASE_URL") and os.getenv("AI_PROVIDER_API_KEY") and os.getenv("AI_PROVIDER_MODEL"))}


@app.post("/v1/ai/{task}")
async def ai_text(task: str, data: dict, user=Depends(verified_user)):
    models = {"story": StoryInput, "dialogue": DialogueInput, "scenes": ScenesInput}
    if task not in models:
        raise HTTPException(status_code=404, detail="Unsupported AI task")
    try:
        validated = models[task].model_validate(data)
    except Exception as exc:
        raise HTTPException(status_code=422, detail="Invalid request fields") from exc
    result = await generate_text(make_prompt(task, validated))
    return {"result": result, "task": task}
