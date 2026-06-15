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
    parser.add_argument("--ckpt_path", required=True, help="Path to pretrained model")
    parser.add_argument("--data", required=True, help="Path to folder with images")
    parser.add_argument("--output_path", help="Path to save the output files.")
    parser.add_argument("--batch_size")
    parser.add_argument("--tile_size", nargs="+", type=int, help="2D or 3D")
    parser.add_argument("--tile_overlap", nargs="+", type=int, help="2D or 3D")
    parser.add_argument("--axes")
    parser.add_argument("--data_type", type=SupportedData)
    parser.add_argument("--write_type")
    args = parser.parse_args()

    prediction_careamist(
        args.ckpt_path,
        args.data_path,
        args.batch_size,
        args.tile_size,
        args.tile_overlap,
        args.axes,
        args.data_type,
        args.write_type,
        args.output_path
    )
