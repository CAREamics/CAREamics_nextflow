# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "careamics-portfolio",
#     "pandas",
# ]
# ///

import argparse
import logging
from pathlib import Path

from careamics_portfolio import PortfolioManager
import pandas as pd

logger = logging.getLogger(__file__)


def main(work_dir: Path):

    # instantiate data portfolio manage
    portfolio = PortfolioManager()

    # and download the data
    root_path = work_dir / "data"
    files = portfolio.denoising.N2V_SEM.download(root_path)
    logger.info(f"N2V example data downloaded at: {files}")

    df = pd.DataFrame({"id": [0], "data_path": [files[0]]})
    df.to_csv(work_dir / "example_n2v_predict.csv", index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--work_dir",
        "-wd",
        type=Path,
        required=True,
        help="Nextflow working directory.",
    )
    args = parser.parse_args()
    main(args.work_dir)
