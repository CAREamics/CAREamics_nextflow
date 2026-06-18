#!/usr/bin/env nextflow
nextflow.enable.dsl=2

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
    
    //
    // STEP 1: DENOISING
    //
    
    if (params.pretrained_model) {
        // Use pre-trained model for denoising
        log.info "Using pre-trained model: ${params.pretrained_model}"
        
        ch_input_images = channel
            .fromPath(params.input, checkIfExists: true)
            .map { file -> 
                def meta = [id: file.baseName]
                return [meta, file]
            }
        
        ch_pretrained_model = channel
            .fromPath(params.pretrained_model, checkIfExists: true)
            .map { model -> [[id: 'pretrained'], model] }
        
        ch_predict_input = ch_input_images
            .combine(ch_pretrained_model)
            .map { img_meta, img_file, _model_meta, model_file ->
                [img_meta, img_file, model_file]
            }
        
        CAREAMICS_PREDICT(ch_predict_input)
        ch_denoised = CAREAMICS_PREDICT.out.predictions
        
    } else if (params.train_csv) {
        // Train model first, then denoise
        log.info "Training ${params.model} model from CSV and denoising"
        
        // Prepare training data from CSV
        ch_training = channel
            .fromPath(params.train_csv, checkIfExists: true)
            .splitCsv(header: true)
            .map { row ->
                def meta = [id: row.sample, model: params.model]
                def imagePath = file(row.image, checkIfExists: true)
                
                if (params.model == 'n2v') {
                    // N2V only needs noisy images
                    return [meta, imagePath]
                } else {
                    // CARE and N2N need paired data
                    if (!row.target) {
                        error "CSV must have 'target' column for model: ${params.model}"
                    }
                    def targetPath = file(row.target, checkIfExists: true)
                    return [meta, imagePath, targetPath]
                }
            }
        
        // Train based on model type
        if (params.model == 'n2v') {
            CAREAMICS_TRAIN_N2V(ch_training)
            ch_trained_model = CAREAMICS_TRAIN_N2V.out.model
        } else if (params.model == 'care') {
            CAREAMICS_TRAIN_CARE(ch_training)
            ch_trained_model = CAREAMICS_TRAIN_CARE.out.model
        } else if (params.model == 'n2n') {
            CAREAMICS_TRAIN_N2N(ch_training)
            ch_trained_model = CAREAMICS_TRAIN_N2N.out.model
        } else {
            error "Unknown model type: ${params.model}. Use 'n2v', 'care', or 'n2n'"
        }
        
        // Prepare test images for denoising
        ch_test_images = channel
            .fromPath(params.input, checkIfExists: true)
            .map { file -> [[id: file.baseName], file] }
        
        // Combine test images with trained model
        ch_predict_input = ch_test_images
            .combine(ch_trained_model)
            .map { test_meta, test_file, model_meta, model_file ->
                def merged_meta = test_meta + [model_id: model_meta.id]
                return [merged_meta, test_file, model_file]
            }
        
        CAREAMICS_PREDICT(ch_predict_input)
        ch_denoised = CAREAMICS_PREDICT.out.predictions
        
    } else {
        error """
        Please provide either:
        1. A pre-trained model: --pretrained_model path/to/model.ckpt
        2. Training CSV: --train_csv path/to/training.csv
        """
    }
}
