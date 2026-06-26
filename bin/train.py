#!/usr/bin/env python3

from pathlib import Path
import argparse

from careamics import CAREamist
from careamics.config.utils.configuration_io import load_configuration


def without_none(kwargs):
    return {key: value for key, value in kwargs.items() if value is not None}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output_path", type=Path, required=True, help="Path to save the output files."
    )
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument(
        "--train_data", type=str, required=True, help="Path to train data."
    )
    parser.add_argument(
        "--train_target", type=str, required=True, help="Path to target data."
    )
    parser.add_argument(
        "--val_data", type=str, default=None, help="Path to validation data."
    )
    parser.add_argument(
        "--val_target", type=str, default=None, help="Path to validation target data."
    )
    # TODO: add filtering mask?

    args = parser.parse_args()

    config = load_configuration(args.config)
    # TODO: have to make sure that checkpoint callback is saving last checkpoint?
    # TODO: export last/best checkpoint name?

    careamist = CAREamist(config=config, work_dir=args.output_path)
    careamist.train(
        train_data=args.train_data,
        train_data_target=args.train_target,
        **without_none({"val_data": args.val_data, "val_data_target": args.val_target}),
    )
