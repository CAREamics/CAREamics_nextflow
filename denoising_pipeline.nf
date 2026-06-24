#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
========================================================================================
    CAREamics Denoising 
========================================================================================
    Example pipeline demonstrating:
    1. Denoise microscopy images using CAREamics (N2V, CARE, or N2N)
    
    Usage:
        nextflow run example_denoising_segmentation_pipeline.nf \
            -profile conda|singularity|docker \
            -params-file params_n2v.json|params_n2n_care.json
========================================================================================
*/

// Import CAREamics modules
include { CAREAMICS_TRAIN_N2V  } from './modules/careamics/train/n2v/main'
include { CAREAMICS_TRAIN_CARE } from './modules/careamics/train/care/main'
include { CAREAMICS_TRAIN_N2N  } from './modules/careamics/train/n2n/main'
include { CAREAMICS_PREDICT    } from './modules/careamics/predict/main'


/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {
    if (params.pretrained_model) {
        // Use pre-trained model for restoration
        log.info("Using pre-trained model: ${params.pretrained_model}")

        ch_model = channel.fromPath(params.pretrained_model, checkIfExists: true)
            .map { model -> [[id: 'pretrained'], model] }
    }
    else if (params.train_data) {
        // Train model first
        log.info("Training ${params.algorithm} algorithm and restoration prediction samples")

        def train_meta = [id: params.experiment_name]
        if (params.algorithm == 'n2v') {
            ch_training = channel.of([train_meta, file(params.train_data), file(params.val_data)])
            CAREAMICS_TRAIN_N2V(ch_training)
            ch_model = CAREAMICS_TRAIN_N2V.out.model
        }
        else if (params.algorithm == 'care') {
            if (!params.train_target) {
                error("Please provide --train_target for algorithm: ${params.algorithm}")
            }
            if (params.val_data && !params.val_target) {
                error(
                    "Please provide both --val_data and --val_target for algorithm: ${params.algorithm}, or neither."
                )
            }
            ch_training = channel.of(
                [
                    train_meta,
                    file(params.train_data),
                    file(params.train_target),
                    file(params.val_data) ?: [],
                    file(params.val_target) ?: [],
                ]
            )
            CAREAMICS_TRAIN_CARE(ch_training)
            ch_model = CAREAMICS_TRAIN_CARE.out.model
        }
        else if (params.algorithm == 'n2n') {
            if (!params.train_target) {
                error("Please provide --train_target for algorithm: ${params.algorithm}")
            }
            if (params.val_data && !params.val_target) {
                error("Please provide both --val_data and --val_target for algorithm: ${params.algorithm}, or neither.")
            }
            ch_training = channel.of(
                [
                    train_meta,
                    file(params.train_data),
                    file(params.train_target),
                    file(params.val_data) ?: [],
                    file(params.val_target) ?: [],
                ]
            )
            CAREAMICS_TRAIN_N2N(ch_training)
            ch_model = CAREAMICS_TRAIN_N2N.out.model
        }
        else {
            error("Unknown algorithm: ${params.algorithm}. Use 'n2v', 'care', or 'n2n'")
        }
    }
    else {
        error(
            """
            Please provide either:
            1. A pre-trained model: --pretrained_model path/to/model.ckpt
            2. Training data (and target data for care & n2n): --train_data path/to/train --train_target path/to/target
            """
        )
    }

    // Run prediction
    ch_prediction_data = channel.fromPath(params.prediction_csv, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            if (!row.data_path) {
                error("Prediction CSV must contain an 'data_path' column")
            }
            def predictionPath = file(row.data_path, checkIfExists: true)
            def meta = [id: row.id ?: predictionPath.baseName]
            return [meta, predictionPath]
        }
    ch_predict_input = ch_prediction_data
        .combine(ch_model)
        .map { prediction_meta, prediction_path, model_meta, model_file ->
            def merged_meta = prediction_meta + [model_id: model_meta.id]
            return [merged_meta, prediction_path, model_file]
        }
    CAREAMICS_PREDICT(ch_predict_input)
    ch_prediction = CAREAMICS_PREDICT.out.predictions
}
