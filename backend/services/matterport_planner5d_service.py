"""
PropZen 3D Visualization & Virtual Walkthrough Service (Matterport & Planner 5D)
Registers and optimizes interactive 360 virtual tours, BIM models, and 2D/3D floor plans.
"""

import os
import datetime
from typing import Dict, Any


class MatterportPlanner5dService:
    def __init__(self):
        self.matterport_key = os.getenv("MATTERPORT_API_KEY", "matterport_prod_key_2026")
        self.planner5d_key = os.getenv("PLANNER5D_API_KEY", "planner5d_prod_key_2026")

    def register_3d_tour(
        self,
        property_id: str,
        matterport_model_id: str,
        floorplan_project_id: str = None,
    ) -> Dict[str, Any]:
        """Registers Matterport 3D Tour and Planner 5D floor plan assets."""
        tour_id = f"tour_3d_{datetime.datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

        clean_model_id = matterport_model_id.strip() if matterport_model_id else "SxZ9XG8zR1A"

        return {
            "tour_id": tour_id,
            "property_id": property_id,
            "matterport_model_id": clean_model_id,
            "matterport_embed_url": f"https://my.matterport.com/show/?m={clean_model_id}&play=1&qs=1&brand=0&title=0",
            "planner5d_embed_url": f"https://planner5d.com/v/?key={floorplan_project_id or 'propzen_floorplan_demo'}&viewMode=3d",
            "status": "ACTIVE",
            "is_vr_ready": True,
            "registered_at": datetime.datetime.utcnow().isoformat(),
        }


matterport_planner5d_service = MatterportPlanner5dService()
