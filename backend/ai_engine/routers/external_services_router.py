"""
FastAPI Router for PropZen 9 External Service Integrations
(Wati, Apify, Signzy, eCourt, HeyGen, ElevenLabs, Matterport/Planner5D, YouTube)
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional

from ..services.wati_service import wati_service
from ..services.apify_service import apify_service
from ..services.signzy_service import signzy_service
from ..services.ecourt_service import ecourt_service
from ..services.heygen_service import heygen_service
from ..services.elevenlabs_service import elevenlabs_service
from ..services.matterport_planner5d_service import matterport_planner5d_service
from ..services.youtube_service import youtube_service

router = APIRouter(prefix="/api/v1", tags=["External Services & AI Pipelines"])


# ==============================================================================
# 1. WATI WHATSAPP MARKETING & COMMUNICATION
# ==============================================================================
class WatiTemplateRequest(BaseModel):
    whatsapp_number: str
    template_name: str
    parameters: List[Dict[str, str]] = []
    broadcast_name: str = "Lead_Notification"


@router.post("/wati/send-template")
async def send_wati_template_endpoint(payload: WatiTemplateRequest):
    return wati_service.send_template_message(
        whatsapp_number=payload.whatsapp_number,
        template_name=payload.template_name,
        parameters=payload.parameters,
        broadcast_name=payload.broadcast_name,
    )


# ==============================================================================
# 2. APIFY PERMITTED MARKET SCRAPER
# ==============================================================================
class ApifyScrapeRequest(BaseModel):
    location: str
    city: str = "Noida"


@router.post("/apify/scrape-market")
async def run_apify_scraper_endpoint(payload: ApifyScrapeRequest):
    return apify_service.run_market_data_scraper(
        location=payload.location,
        city=payload.city,
    )


# ==============================================================================
# 3. SIGNZY KYC & PAN VERIFICATION
# ==============================================================================
class SignzyPanRequest(BaseModel):
    pan_number: str
    full_name: str


@router.post("/signzy/verify-pan")
async def verify_pan_endpoint(payload: SignzyPanRequest):
    return signzy_service.verify_pan_card(
        pan_number=payload.pan_number,
        full_name=payload.full_name,
    )


# ==============================================================================
# 4. OFFICIAL eCOURT LITIGATION CHECK
# ==============================================================================
class ECourtSearchRequest(BaseModel):
    cnr_number: str
    court_complex: str = "District Court Gautam Buddha Nagar"


@router.post("/ecourt/search")
async def search_ecourt_endpoint(payload: ECourtSearchRequest):
    return ecourt_service.search_litigation_records(
        cnr_number=payload.cnr_number,
        court_complex=payload.court_complex,
    )


# ==============================================================================
# 5. HEYGEN AI VIDEO EXPLAINER
# ==============================================================================
class HeyGenVideoRequest(BaseModel):
    property_id: str
    property_title: str
    script_text: str
    locality: str


@router.post("/heygen/create-explainer")
async def create_heygen_video_endpoint(payload: HeyGenVideoRequest):
    return heygen_service.create_property_explainer_video(
        property_id=payload.property_id,
        property_title=payload.property_title,
        script_text=payload.script_text,
        locality=payload.locality,
    )


# ==============================================================================
# 6. ELEVENLABS AI VOICE SYNTHESIS
# ==============================================================================
class ElevenLabsVoiceRequest(BaseModel):
    property_id: str
    script_text: str
    language: str = "en"


@router.post("/elevenlabs/synthesize")
async def synthesize_voice_endpoint(payload: ElevenLabsVoiceRequest):
    return elevenlabs_service.synthesize_property_voiceover(
        property_id=payload.property_id,
        script_text=payload.script_text,
        language=payload.language,
    )


# ==============================================================================
# 7. MATTERPORT & PLANNER 5D 3D TOURS
# ==============================================================================
class VirtualTourRequest(BaseModel):
    property_id: str
    matterport_model_id: str
    floorplan_project_id: Optional[str] = None


@router.post("/visualization/register-3d-tour")
async def register_3d_tour_endpoint(payload: VirtualTourRequest):
    return matterport_planner5d_service.register_3d_tour(
        property_id=payload.property_id,
        matterport_model_id=payload.matterport_model_id,
        floorplan_project_id=payload.floorplan_project_id,
    )


# ==============================================================================
# 8. YOUTUBE DATA API AUTOMATION
# ==============================================================================
class YouTubePublishRequest(BaseModel):
    property_id: str
    title: str
    description: str
    video_source_url: str
    tags: Optional[List[str]] = None


@router.post("/youtube/publish-video")
async def publish_youtube_video_endpoint(payload: YouTubePublishRequest):
    return youtube_service.publish_property_video(
        property_id=payload.property_id,
        title=payload.title,
        description=payload.description,
        video_source_url=payload.video_source_url,
        tags=payload.tags,
    )
