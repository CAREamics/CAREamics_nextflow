# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pandas",
#     "pooch",
#     "tqdm",
# ]
# ///

import argparse
import logging
from pathlib import Path

import pandas as pd
import pooch

logger = logging.getLogger(__file__)

DATA_URL = (
    "https://dl-at-mbl-2023-data.s3.us-east-2.amazonaws.com/image_restoration_data.zip"
)
DATA_SHA256 = "4112d3666a4f419bbd51ab0b7853c12e16c904f89481cbe7f1a90e48f3241f72"


def main(work_dir: Path) -> None:
    data_path = work_dir / "data"

    # Use the same archive and extracted directory name as the CAREamics portfolio.
    pooch.retrieve(
        url=DATA_URL,
        known_hash=f"sha256:{DATA_SHA256}",
        fname="denoising-CARE_U2OS",
        path=data_path,
        processor=pooch.Unzip(),
        progressbar=True,
    )

    root_path = data_path / "denoising-CARE_U2OS.unzip" / "data" / "U2OS"
    _ = root_path / "train" / "low"
    _ = root_path / "train" / "GT"
    test_path = root_path / "test" / "low"

    prediction_csv = work_dir / "example_care_predict.csv"
    pd.DataFrame({"id": ["U2OS"], "data_path": [test_path]}).to_csv(
        prediction_csv, index=False
    )

    logger.info("CARE U2OS example data downloaded to %s", root_path)
    logger.info("Prediction CSV written to %s", prediction_csv)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
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
