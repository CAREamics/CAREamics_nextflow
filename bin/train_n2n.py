#!/usr/bin/env python3

from pathlib import Path
import argparse
import os
from typing import Any, Sequence

from careamics import CAREamist
from careamics.config import create_n2n_config
from careamics.config.support import SupportedData
from careamics.config.configuration import Configuration
from careamics.config.utils.configuration_io import save_configuration


def without_none(kwargs: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in kwargs.items() if value is not None}


def create_config(
    exp_name: str,
    data_type: SupportedData,
    axes: str,
    patch_size: tuple[int, ...],
    batch_size: int,
    num_epochs: int | None = None,
    num_steps: int | None = None,
    augmentations: Sequence[str] | None = None,
    n_val_patches: int | None = None,
    n_channels_in: int | None = None,
    n_channels_out: int | None = None,
):
    """create the config to train"""
    config = create_n2n_config(
        experiment_name=exp_name,
        data_type=data_type.value,
        axes=axes,
        patch_size=patch_size,
        batch_size=batch_size,
        **without_none(
            {
                "num_epochs": num_epochs,
                "num_steps": num_steps,
                "augmentations": augmentations,
                "n_val_patches": n_val_patches,
                "n_channels_in": n_channels_in,
                "n_channels_out": n_channels_out,
            }
        ),
    )
    return config


def train_model(
    train_path: Path,
    target_path: Path,
    config: Configuration[Any],
    val_path: Path | None = None,
    val_target_path: Path | None = None,
):
    """function to train a model"""
    careamist = CAREamist(config=config)
    careamist.train(
        train_data=train_path,
        train_data_target=target_path,
        **without_none({"val_data": val_path, "val_data_target": val_target_path}),
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--train_data", type=Path, required=True, help="Path to train data.")
    parser.add_argument("--train_target", type=Path, required=True, help="Path to target data.")
    parser.add_argument("--val_data", type=Path, help="Path to validation data.")
    parser.add_argument("--val_target", type=Path, help="Path to validation target data.")
    parser.add_argument("--output_path", type=Path, required=True, help="Path to save the output files.")
    parser.add_argument("--experiment_name", type=str, required=True, help="name of the experiment.")
    parser.add_argument("--data_type", type=SupportedData, required=True)
    parser.add_argument("--axes", type=str, required=True)
    parser.add_argument("--patch_size", nargs="+", type=int, required=True, help="2D or 3D")
    parser.add_argument("--batch_size", type=int, required=True)
    parser.add_argument("--num_epochs", type=int)
    parser.add_argument("--num_steps", type=int)
    parser.add_argument(
        "--augmentations", nargs="+", choices=["x_flip", "y_flip", "rotate_90"]
    )
    parser.add_argument("--n_val_patches", type=int)
    parser.add_argument("--n_channels_in", type=int)
    parser.add_argument("--n_channels_out", type=int)

    args = parser.parse_args()
    
    config = create_config(
        args.experiment_name,
        args.data_type,
        args.axes,
        args.patch_size,
        args.batch_size,
        num_epochs=args.num_epochs,
        num_steps=args.num_steps,
        augmentations=args.augmentations,
        n_val_patches=args.n_val_patches,
        n_channels_in=args.n_channels_in,
        n_channels_out=args.n_channels_out,
    )
    save_configuration(config, os.path.join(args.output_path, "config.yaml"))
    train_model(args.train_data, args.train_target, config, args.val_data, args.val_target)
