#!/bin/bash

## NEED TO BE MODIFIED BY THE ANALYST
IGGMC="<path-to-IGGMC-analysis-tool>"   #need to setup; see README.md
DATADIR="<absolute-path-to-data>" 	#need to setup; see README.md
##

# Check that external tools are accessible:
FQDUMP=`which fastq-dump`;
TAIL=`which tail`;
CAT=`which cat`;
TOUCH=`which touch`;
MKDIR=`which mkdir`

if [[ -z "${FQDUMP}" || ! -x "${FQDUMP}" ]]; then
    error 127 "SRA TOOLKIT's fastq-dump not in PATH env variable or not executable";

elif [[ -z "${TAIL}" || ! -x "${TAIL}" ]]; then
    error 127 "tail not in PATH env variable or not executable";

elif [[ -z "${CAT}" || ! -x "${CAT}" ]]; then
    error 127 "cat not in PATH env variable or not executable";

elif [[ -z "${MKDIR}" || ! -x "${MKDIR}" ]]; then
    error 127 "mkdir not in PATH env variable or not executable";

elif [[ -z "${TOUCH}" || ! -x "${TOUCH}" ]]; then
    error 127 "mkdir not in PATH env variable or not executable";

fi

if [[ ! -e "${DATADIR}/data.complete" ]]; then
    echo "executing" >&2;

    SAMPLE="${DATADIR}/sra_metadata_acc-himp-1r-processed-ok.tsv"

    [ -d "${DATADIR}/HIMP1_1" ] || ${MKDIR} "${DATADIR}/HIMP1_1";

    cat ${SAMPLE} | ${TAIL} -n +2 | while IFS=$'\t' read accession study object_status bioproject_accession biosample_accession library_ID title library_strategy library_source library_selection library_layout platform instrument_model design_description filetype filename; do
	library_ID=`echo $library_ID | awk '{split($1,lib,"-"); print lib[1]""lib[2]}'`
	echo "${FQDUMP} --gzip -Z -A $accession > ${DATADIR}/HIMP1_1/HIMP1_1-${library_ID}_0.fastq.gz";
    done >data.batch 

    SAMPLE="${DATADIR}/sra_metadata_acc-himp-2-processed-ok.tsv"

    [ -d "HIMP2_1" ] || ${MKDIR} "HIMP2_1";

    cat ${SAMPLE} | ${TAIL} -n +2 | while IFS=$'\t' read accession study object_status bioproject_accession biosample_accession library_ID title library_strategy library_source library_selection library_layout platform instrument_model design_description filetype filename; do
	library_ID=`echo $library_ID | awk '{split($1,lib,"-"); print lib[1]""lib[2]}'`
	echo "${FQDUMP} --gzip -Z -A $accession > ${DATADIR}/HIMP2_1/HIMP2_1-${library_ID}_0.fastq.gz";
    done >>data.batch && \
       	${IGGMC}/scripts/qbatch submit -n data-HIMP -q normal.c -Wj -R 1 ${DATADIR}/data.batch && \
     	${TOUCH} data.complete;

else
    echo "current" >&2;
fi
