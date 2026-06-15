#!/usr/bin/env python3

from pathlib import Path
import argparse
import os

from careamics import CAREamist
from careamics.config import create_n2v_config
from careamics.config.support import SupportedData
from careamics.config.configuration import Configuration
from careamics.config.utils.configuration_io import save_configuration


def create_config(
    exp_name: str,
    data_type: SupportedData,
    axes: str,
    patch_size: tuple[int, ...],
    batch_size: int,
    num_epochs: int,
    n2v2: bool,
) -> Configuration:
    """create the config to train"""
    config = create_n2v_config(
        experiment_name=exp_name,
        data_type=data_type.value,
        axes=axes,
        patch_size=patch_size,
        batch_size=batch_size,
        num_epochs=num_epochs,
        use_n2v2=n2v2,
    )
    return config


def train_model(train_path: Path, config: Configuration, work_dir: str):
    """function to train a model"""
    careamist = CAREamist(config=config, work_dir=work_dir)
    careamist.train(
        train_data=train_path,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--experiment_name", type=str, help="name of the experiment.")
    parser.add_argument("--data_type", type=SupportedData)
    parser.add_argument("--axes", type=str)
    parser.add_argument("--patch_size", nargs="+", type=int, help="2D or 3D")
    parser.add_argument("--batch_size", type=int)
    parser.add_argument("--num_epochs", type=int)
    parser.add_argument("--use_n2v2", type=bool)
    parser.add_argument("--train_data", help="Path to train data.")
    parser.add_argument("--output_path", help="Path to save the output files.")

    args = parser.parse_args()

    config = create_config(
        args.experiment_name,
        args.data_type,
        args.axes,
        args.patch_size,
        args.batch_size,
        args.num_epochs,
        args.use_n2v2
    )
    save_configuration(config, os.path.join(args.output_path, "config.yaml"))
    train_model(args.train_data, config, work_dir=args.output_path)
