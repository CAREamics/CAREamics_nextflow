#!/usr/bin/env python3

import argparse
from pathlib import Path
from typing import Literal

from careamics import CAREamist
from careamics.config.support import SupportedData


def prediction_careamist(
    ckpt_path: Path,
    data_path: Path,
    batch_size: int,
    tile_size: tuple[int, ...],
    tile_overlap: tuple[int, ...],
    axes: str,
    data_type: SupportedData,
    write_type: Literal["tiff", "zarr", "custom"],
    output_path: Path,
):
    """function to denoised a dataset according to a pretrained model using careamics"""
    careamics_pretrained = CAREamist(checkpoint_path=ckpt_path)
    careamics_pretrained.predict_to_disk(
        pred_data=data_path,
        prediction_dir=output_path / "predictions",
        batch_size=batch_size,
        tile_size=tile_size,
        tile_overlap=tile_overlap,
        axes=axes,
        data_type=data_type.value,
        write_type=write_type,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ckpt_path", type=Path, required=True, help="Path to pretrained model")
    parser.add_argument("--data", type=Path, required=True, help="Path to folder with images")
    parser.add_argument(
        "--output_path", type=Path, help="Path to save the output files.", default=Path(".")
    )
    parser.add_argument("--batch_size", type=int)
    parser.add_argument("--tile_size", nargs="+", type=int, help="2D or 3D")
    parser.add_argument("--tile_overlap", nargs="+", type=int, help="2D or 3D")
    parser.add_argument("--axes", type=str)
    parser.add_argument("--data_type", type=SupportedData)
    parser.add_argument("--write_type", choices=["tiff", "zarr", "custom"])
    args = parser.parse_args()

    prediction_careamist(
        args.ckpt_path,
        args.data,
        args.batch_size,
        args.tile_size,
        args.tile_overlap,
        args.axes,
        args.data_type,
        args.write_type,
        args.output_path,
    )
