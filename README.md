# Carrier Install Base Intelligence

Art-of-the-Possible prototype for Carrier. Turns fragmented install-base data — ERP records, paper service histories, field estimates, technician notes — into a live intelligence layer for service operations, dealer performance, and aftermarket growth.

## Pages

- **Executive Command Center** — $175.3M Year 1 value story, territory opportunity ranking, contract recovery trend
- **Unit Intelligence** — hero unit U-4006: reconstructed service history, component risk, recommended parts kit
- **Data Recovery** — OCR + normalization pipeline that turns paper records into queryable unit history ($15M value line)
- **Fleet Insights** — recurring failure pattern detection (FP-001: condenser fan motor across RTUs)
- **Dealer Intelligence** — territory opportunity map, dealer benchmarks, account opportunity ranking, $5M contract recovery
- **Dispatch Copilot** — pre-dispatch AI brief, staged parts kit, second-trip risk prediction
- **Alerts** — severity-ranked queue with routing + escalation logic

## Stack

Single-file prototype: React + Tailwind + Recharts via CDN, no build step. Deploys as static HTML to Vercel.

## Deploy

Auto-deploys on push to `main` once the Vercel project is connected to this repo.

Manual deploy (no GitHub needed):

    python3 deploy.py <VERCEL_TOKEN>
