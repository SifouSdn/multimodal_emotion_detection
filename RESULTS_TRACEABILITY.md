# Results Traceability Map

Last updated: 2026-04-12

## Purpose
This file links each canonical manuscript metric claim to:
- source artifact,
- producing script entry point,
- reproduction command,
- verification command.

Use this file together with `METRIC_PROVENANCE_LEDGER.md` for submission audits.

## Canonical Claims (M01-M09)

| Claim ID | Metric | Artifact | Producer Script | Reproduction Command | Verification Command | Notes |
|---|---|---|---|---|---|---|
| M01 | MELD stacked peak weighted F1 (71.56%) | `outputs/exp13_temporal_ensemble_results.json` (`overall_best_f1`) | `exp13_temporal_ensemble.py` | `python .\exp13_temporal_ensemble.py` | `(Get-Content .\outputs\exp13_temporal_ensemble_results.json | ConvertFrom-Json).overall_best_f1` | Canonical headline value. |
| M02 | MELD 3-model stack weighted F1 (71.53%) | `outputs/exp12_sota_final/final_results.json` (`ablation[3].wf1`) | `train_exp12_sota_final.py` | `python .\train_exp12_sota_final.py --output_dir outputs/exp12_sota_final` | `(Get-Content .\outputs\exp12_sota_final\final_results.json | ConvertFrom-Json).ablation[3].wf1` | Combination: exp05+exp07v1+exp12_ep1. |
| M03 | MELD LR stack weighted F1 (70.86%) | `outputs/exp12_sota_final/final_results.json` (`lr.weighted_f1`) | `train_exp12_sota_final.py` | `python .\train_exp12_sota_final.py --output_dir outputs/exp12_sota_final` | `(Get-Content .\outputs\exp12_sota_final\final_results.json | ConvertFrom-Json).lr.weighted_f1` | Same run family as M02. |
| M04 | MELD->IEMOCAP zero-shot weighted F1 (49.04%) | `outputs/exp10_cross_corpus/results.json` (`option_a_cross_corpus.lr_stacking_C6.weighted_f1`) | `run_exp10_cross_corpus.py` | `python .\run_exp10_cross_corpus.py` | `(Get-Content .\outputs\exp10_cross_corpus\results.json | ConvertFrom-Json).option_a_cross_corpus.lr_stacking_C6.weighted_f1` | Cross-corpus degradation metric (one-direction canonical evidence in this freeze). |
| M05 | Parser fallback ratio before parser fix (79.28%) | `outputs/recovery_fast_val/eval_metrics_10pct.json` (`meld_metrics.parser_fallback_ratio`) | `autoresearch_evaluator.py` (historical pre-fix parser behavior) | Historical artifact from pre-fix parser logic; exact regeneration requires historical parser state. | `(Get-Content .\outputs\recovery_fast_val\eval_metrics_10pct.json | ConvertFrom-Json).meld_metrics.parser_fallback_ratio` | Pre-fix baseline retained for audit comparison. |
| M06 | Parser fallback ratio after parser fix (0.00%) | `outputs/recovery_fast_val/eval_metrics_10pct_after_parser_fix.json` (`meld_metrics.parser_fallback_ratio`) | `autoresearch_evaluator.py` + current parser utilities (`emotion_instruction_utils.py`) | `python .\autoresearch_evaluator.py --repo_root . --exp51_output_dir outputs/recovery_fast_val --lora_dir outputs/recovery_fast_val/lora_latest --projector_path outputs/recovery_fast_val/projector_latest.pt --sample_ratio 0.1 --metrics_json outputs/recovery_fast_val/eval_metrics_10pct_after_parser_fix.json` | `(Get-Content .\outputs\recovery_fast_val\eval_metrics_10pct_after_parser_fix.json | ConvertFrom-Json).meld_metrics.parser_fallback_ratio` | Post-fix parser metric used in manuscript reliability discussion. |
| M07 | Distilled single-model weighted F1 (68.29%) | `outputs/exp32_v3_avg_results.log` (`Test WF1: 0.6829`) | `checkpoint_avg_exp32.py` (uses `train_exp32_distill_deep.py` checkpoints) | `python .\checkpoint_avg_exp32.py | Tee-Object -FilePath .\outputs\exp32_v3_avg_results.log` | `Select-String -Path .\outputs\exp32_v3_avg_results.log -Pattern "Test WF1: 0.6829" -Encoding Unicode` | Log is UTF-16; use `-Encoding Unicode` for search. |
| M08 | Naive additive fusion weighted F1 (49.55%, dev) | `outputs/exp31_deep_v11/train_log.txt` (`Best dev WF1: 0.4955`) | `train_exp31_deep_alignment.py` | `python .\train_exp31_deep_alignment.py --fusion_mode fixed --fixed_alpha 0.1 --output_dir outputs/exp31_deep_v11` | `Select-String -Path .\outputs\exp31_deep_v11\train_log.txt -Pattern "Best dev WF1: 0.4955"` | Dev stress run; not a test-set headline. |
| M09 | Recovery branch dev weighted F1 (57.87%) | `outputs/recovery_R9b_kd_k4_fullDev/metrics_best.json` (`dev_weighted_f1`) | `train.py` | `python .\train.py --output_dir outputs/recovery_R9b_kd_k4_fullDev --projector_type perceiver --num_audio_tokens 4 --skip_projector_checkpoint_load --scheduler_type linear --warmup_steps 40 --min_lr_ratio 0.1 --sampling_strategy shuffle --loss_strategy ce --use_kd --kd_alpha 0.3 --kd_temperature 2.0 --checkpoint_macro_f1_min 0.10 --checkpoint_minority_f1_min 0.02 --checkpoint_neutral_ratio_max 0.85 --eval_every_steps 80 --dev_eval_batches 0 --max_steps 320 --max_train_minutes 240 --batch_size 2 --grad_accum 4 --num_workers 0 --seed 42` | `(Get-Content .\outputs\recovery_R9b_kd_k4_fullDev\metrics_best.json | ConvertFrom-Json).dev_weighted_f1` | Reproduction command captured from `run_manifest.jsonl`. |

## Notes
- The one-command verification script (`verify_submission_bundle.ps1`) checks artifact values and evidence lines, but this file supplies explicit producer entry points.
- For historical pre-fix parser behavior (M05), preserve artifact as audit evidence even when exact regeneration requires historical parser-state checkout.
