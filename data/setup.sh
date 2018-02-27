#!/bin/bash

# Check that external tools are accessible:
FQDUMP=`which fastq-dump`;
TAIL=`which tail`;
CAT=`which cat`;
MKDIR=`which mkdir`

if [[ -z "${FQDUMP}" || ! -x "${FQDUMP}" ]]; then
    error 127 "SRA TOOLKIT's fastq-dump not in PATH env variable or not executable";

elif [[ -z "${TAIL}" || ! -x "${TAIL}" ]]; then
    error 127 "tail not in PATH env variable or not executable";

elif [[ -z "${CAT}" || ! -x "${CAT}" ]]; then
    error 127 "cat not in PATH env variable or not executable";

elif [[ -z "${MKDIR}" || ! -x "${MKDIR}" ]]; then
    error 127 "mkdir not in PATH env variable or not executable";

fi

SAMPLE="sra_metadata_acc-himp-1r-processed-ok.tsv"

[ -d "HIMP1_1" ] || ${MKDIR} "HIMP1_1";

cat ${SAMPLE} | ${TAIL} -n +2 | while IFS=$'\t' read accession study object_status bioproject_accession biosample_accession library_ID title library_strategy library_source library_selection library_layout platform instrument_model design_description filetype filename; do
	library_ID=`echo $library_ID | awk '{split($1,lib,"-"); print lib[1]""lib[2]}'`
	echo "fastq-dump --gzip -Z -A $accession > HIMP1_1/HIMP1_1-${library_ID}_0.fastq.gz"

done

SAMPLE="sra_metadata_acc-himp-2-processed-ok.tsv"

[ -d "HIMP2_1" ] || ${MKDIR} "HIMP2_1";

cat ${SAMPLE} | ${TAIL} -n +2 | while IFS=$'\t' read accession study object_status bioproject_accession biosample_accession library_ID title library_strategy library_source library_selection library_layout platform instrument_model design_description filetype filename; do
	library_ID=`echo $library_ID | awk '{split($1,lib,"-"); print lib[1]""lib[2]}'`
	echo "fastq-dump --gzip -Z -A $accession > HIMP2_1/HIMP2_1-${library_ID}_0.fastq.gz"

done
