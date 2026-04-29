from pathlib import Path

from export_dashboard_json import COMPLETED_TOKENS_PATH, prepare_completed_tokens, build_daily_process_breakdown

completed = prepare_completed_tokens(Path(COMPLETED_TOKENS_PATH))
payload = build_daily_process_breakdown(completed)

for modality in payload.get("modalities", []):
    dates = [point.get("date") for point in modality.get("points", [])]
    if dates:
        print(modality.get("modality"), dates[-5:])
