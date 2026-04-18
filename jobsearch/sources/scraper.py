"""Best-effort generic job-page scraper.

WARNING: Scraping LinkedIn and Indeed violates their Terms of Service and can
trigger captchas or account suspension. Prefer the `linkedin_email` source for
LinkedIn. Use this scraper only for company careers pages and job boards where
you have permission (e.g. your own saved listings, public careers pages).

The user must pass --confirm-tos to the CLI before this runs.
"""

from .manual import add as _manual_add


def scrape(url: str, confirm_tos: bool = False) -> int | None:
    if not confirm_tos:
        raise PermissionError(
            "Scraping requires --confirm-tos. Confirm you are not scraping a site "
            "whose Terms of Service prohibit it (e.g. LinkedIn, Indeed)."
        )
    print("[scraper] NOTE: respect site ToS. LinkedIn/Indeed scraping is not supported.")
    return _manual_add(url=url)
