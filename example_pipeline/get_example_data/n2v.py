# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pandas",
#     "pooch",
# ]
# ///

import argparse
import logging
from pathlib import Path

import pooch
import pandas as pd

logger = logging.getLogger(__file__)


def main(work_dir: Path):

    DATA_PATH = Path("data/N2V_SEM")
    # download the data
    train_image = pooch.retrieve(
        "https://zenodo.org/records/21028053/files/train.tif",
        known_hash="8be263564a12381bcc0fc69c4271728f3a794aeed78ef85be5fac95e78f5ff73",
        fname="train.tif",
        path=DATA_PATH
    )
    val_image = pooch.retrieve(
        "https://zenodo.org/records/21028053/files/validation.tif",
        known_hash="6f5cd80d4e7f086432458987ee09c7623b2f0c98568bdf2f05b747d804abfabb",
        fname="validation.tif",
        path=DATA_PATH
    )
    files = (train_image, val_image)

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
