# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "careamics-portfolio",
# ]
# ///

import argparse
import logging
from pathlib import Path

from careamics_portfolio import PortfolioManager

logger = logging.getLogger(__file__)


def main(work_dir: Path):

    # instantiate data portfolio manage
    portfolio = PortfolioManager()

    # and download the data
    root_path = work_dir / "data"
    files = portfolio.denoising.N2V_SEM.download(root_path)
    logger.info(f"N2V example data downloaded at: {files}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--work_dir", "-wd", type=Path, help="Nextflow working directory."
    )
    args = parser.parse_args()
    main(args.work_dir)
