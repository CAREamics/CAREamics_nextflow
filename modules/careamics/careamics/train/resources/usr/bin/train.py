#!/usr/bin/env python3

import argparse
from pathlib import Path

from careamics import CAREamist
from careamics.config.utils.configuration_io import load_configuration
from lightning.pytorch.callbacks import ModelCheckpoint


def without_none(kwargs):
    return {key: value for key, value in kwargs.items() if value is not None}


def get_checkpoint_name(careamist: CAREamist) -> Path:
    model_ckpt_callback = careamist.trainer.checkpoint_callback
    assert isinstance(model_ckpt_callback, ModelCheckpoint)

    # If the best path exists return that
    checkpoint_name = model_ckpt_callback.best_model_path
    if checkpoint_name != "":
        return Path(checkpoint_name)

    # Otherwise return the last checkpoint
    checkpoint_name = model_ckpt_callback.last_model_path
    if checkpoint_name != "":
        return Path(checkpoint_name)

    # Or fallback to the last checkpoint saved.
    checkpoints_all = careamist.get_checkpoints()
    if len(checkpoints_all) == 0:
        raise ValueError(
            "No checkpoints saved. Make sure that the "
            "`training_config.checkpoint_params` in the configuration file has been "
            "set correctly."
        )
    return checkpoints_all[-1]


def save_selected_checkpoint_name(careamist: CAREamist) -> None:
    checkpoint_name = get_checkpoint_name(careamist)
    workdir = careamist.work_dir

    path = workdir / "selected_checkpoint.txt"
    with open(path, "w") as f:
        f.write(str(checkpoint_name.relative_to(workdir.resolve())))


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
        "--train_target", type=str, default=None, help="Path to target data."
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
    save_selected_checkpoint_name(careamist)
