#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
========================================================================================
    CAREamics Denoising 
========================================================================================
    Example pipeline demonstrating:
    1. Denoise microscopy images using CAREamics (N2V, CARE, or N2N)
    
    Usage:
        nextflow run denoising_pipeline.nf \
            -profile conda|singularity|docker \
            --prediction_csv prediction.csv \
            --train_data path/to/train_dir \
            --algorithm n2v|care|n2n
========================================================================================
*/

// Import CAREamics modules
include { CAREAMICS_TRAIN_N2V  } from './modules/careamics/train/n2v/main'
include { CAREAMICS_TRAIN_CARE } from './modules/careamics/train/care/main'
include { CAREAMICS_TRAIN_N2N  } from './modules/careamics/train/n2n/main'
include { CAREAMICS_PREDICT    } from './modules/careamics/predict/main'


def validate_dir(data_path, param_name) {
    def data_dir = data_path.toFile()

    if (!data_dir.isDirectory()) {
        error("${param_name} must point to a directory, but got: ${data_path}")
    }

    return data_path
}


/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {

    if (params.pretrained_model) {
        // Use pre-trained model for denoising
        log.info("Using pre-trained model: ${params.pretrained_model}")

        ch_model = channel.fromPath(params.pretrained_model, checkIfExists: true)
            .map { model -> [[id: 'pretrained'], model] }
    }
    else if (params.train_data) {
        // Train model first, then denoise
        log.info("Training ${params.algorithm} algorithm and denoising prediction samples")

        def trainMeta = [id: params.experiment_name ?: params.algorithm, algorithm: params.algorithm]
        def trainData = validate_dir(file(params.train_data, checkIfExists: true), 'train_data')
        def valData = params.val_data ? validate_dir(file(params.val_data, checkIfExists: true), 'val_data') : []

        // Train based on algorithm
        if (params.algorithm == 'n2v') {
            ch_training = channel.of([trainMeta, trainData, valData])
            CAREAMICS_TRAIN_N2V(ch_training)
            ch_model = CAREAMICS_TRAIN_N2V.out.model
        }
        else if (params.algorithm == 'care') {
            if (!params.target_data) {
                error("Please provide --target_data for algorithm: ${params.algorithm}")
            }
            def targetData = validate_dir(file(params.target_data, checkIfExists: true), 'target_data')
            if ((params.val_data && !params.val_target) || (!params.val_data && params.val_target)) {
                error("Please provide both --val_data and --val_target for algorithm: ${params.algorithm}, or neither.")
            }
            def valTarget = params.val_target ? validate_dir(file(params.val_target, checkIfExists: true), 'val_target') : []
            ch_training = channel.of([trainMeta, trainData, targetData, valData, valTarget])
            CAREAMICS_TRAIN_CARE(ch_training)
            ch_model = CAREAMICS_TRAIN_CARE.out.model
        }
        else if (params.algorithm == 'n2n') {
            if (!params.target_data) {
                error("Please provide --target_data for algorithm: ${params.algorithm}")
            }
            def targetData = validate_dir(file(params.target_data, checkIfExists: true), 'target_data')
            if ((params.val_data && !params.val_target) || (!params.val_data && params.val_target)) {
                error("Please provide both --val_data and --val_target for algorithm: ${params.algorithm}, or neither.")
            }
            def valTarget = params.val_target ? validate_dir(file(params.val_target, checkIfExists: true), 'val_target') : []
            ch_training = channel.of([trainMeta, trainData, targetData, valData, valTarget])
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
            2. Training data: --train_data path/to/train_dir --algorithm n2v|care|n2n
            """
        )
    }

    // Run prediction
    ch_prediction_data = channel.fromPath(params.prediction_csv, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            if (!row.image) {
                error("Prediction CSV must contain an 'image' column")
            }
            def predictionPath = file(row.image, checkIfExists: true)
            def meta = [id: row.sample ?: predictionPath.baseName]
            return [meta, predictionPath]
        }
    ch_predict_input = ch_prediction_data
        .combine(ch_model)
        .map { prediction_meta, prediction_path, model_meta, model_file ->
            def merged_meta = prediction_meta + [model_id: model_meta.id]
            return [merged_meta, prediction_path, model_file]
        }
    CAREAMICS_PREDICT(ch_predict_input)
    ch_denoised = CAREAMICS_PREDICT.out.predictions
}
