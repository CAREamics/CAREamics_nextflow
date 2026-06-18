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
            --model n2v|care|n2n
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
        log.info("Training ${params.model} model and denoising prediction samples")

        def trainMeta = [id: params.experiment_name ?: params.model, model: params.model]
        def trainData = validate_dir(file(params.train_data, checkIfExists: true), 'train_data')

        // Train based on model type
        if (params.model == 'n2v') {
            ch_training = channel.of([trainMeta, trainData])
            CAREAMICS_TRAIN_N2V(ch_training)
            ch_model = CAREAMICS_TRAIN_N2V.out.model
        }
        else if (params.model == 'care') {
            if (!params.target_data) {
                error("Please provide --target_data for model: ${params.model}")
            }
            def targetData = validate_dir(file(params.target_data, checkIfExists: true), 'target_data')
            ch_training = channel.of([trainMeta, trainData, targetData])
            CAREAMICS_TRAIN_CARE(ch_training)
            ch_model = CAREAMICS_TRAIN_CARE.out.model
        }
        else if (params.model == 'n2n') {
            if (!params.target_data) {
                error("Please provide --target_data for model: ${params.model}")
            }
            def targetData = validate_dir(file(params.target_data, checkIfExists: true), 'target_data')
            ch_training = channel.of([trainMeta, trainData, targetData])
            CAREAMICS_TRAIN_N2N(ch_training)
            ch_model = CAREAMICS_TRAIN_N2N.out.model
        }
        else {
            error("Unknown model type: ${params.model}. Use 'n2v', 'care', or 'n2n'")
        }
    }
    else {
        error(
            """
            Please provide either:
            1. A pre-trained model: --pretrained_model path/to/model.ckpt
            2. Training data: --train_data path/to/train_dir --model n2v|care|n2n
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
