#!/bin/bash
# Copyright (c)2013. The Regents of the University of California (Regents).
# All Rights Reserved. Permission to use, copy, modify, and distribute this
# software and its documentation for educational, research, and
# not-for-profit purposes, without fee and without a signed licensing
# agreement, is hereby granted, provided that the above copyright notice,
# this paragraph and the following two paragraphs appear in all copies,
# modifications, and distributions. Contact The Office of Technology
# Licensing, UC Berkeley, 2150 Shattuck Avenue, Suite 510, Berkeley, CA
# 94720-1620, (510) 643-7201, for commercial licensing opportunities.

# Created by Jessen Bredeson, Department of Molecular and Cell Biology,
# University of California, Berkeley.


# IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
# SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
# ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
# REGENTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE

# REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED
# HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO PROVIDE
# MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.



###############################################################################
# NOTES
###############################################################################


# This code assumes the data are single-end, gzip'd fastq files with 33 (sanger
# CASAVA 1.8+) quality offset. It also assumes the user is on a Linux/Unix
# system with an UGE/SGE job queueing/scheduling system or something similar.

# The approach taken below is to process each plate/library independently, then 
# merge all libraries downstream into a single, more manageable BAM.

# It is also worth noting that it is less error-prone to copy and paste these
# lines of code into the command-line (excluding comments), however care should 
# be taken that all of the appropriate paths and variables embedded in them are 
# replaced with their correct values.



###############################################################################
# Code Modification
###############################################################################

# This code was modified to develop the analysis provided in the 
# paper "Design and evaluation of a sequence capture system for genome-wide 
# SNP genotyping of a keystone Neotropical hardwood tree genome" paper 
# to appear in DNA Research Journal (2018).
# This version is distributed from:
# https://github.com/biozzyn/handroanthus-variant-analysis


## WE CAN HARDCODE OPTIONS HERE OR SET THE OPTIONS ON THE COMMAND-LINE:
# SET: a shell variable named $WORKDIR to access workdir path more conveniently
#   and $TARGETTOOL pointing to the target-analysis git dir
WORKDIR=;			# /absolute/path/to/workdir
DATADIR=;			# /absolute/path/to/fastqs
TARGETTOOL=;			# /absolute/path/to/target-analysis
RUNTIME='2:0:0';		# HH:MM:SS max (hard) runtime limit

# SET: a shell variable named $LIBNAME for the current library
MANIFEST=;		        # /path/to/fastq_manifest 
LIBNAME=;			# library_identifier (no whitespace)
GENOME=;			# /absolute/path/to/genome.fasta
SAMPLE=;			# /absolute/path/to/sample.tsv
ADAPTOR=;			# /absolute/path/to/ApeKI_adaptors.fasta
SOURCE=;			# Name of sequencing center (no whitespace)

# SET: the following meta-information variables
FCID=;				# flowcell_id_number (no whitespace);
LANE=;				# flowcell_lane_number (no whitespace);


###############################################################################
##                          NOTHING TO MODIFY BELOW                          ##
###############################################################################

# Check that external tools are accessible:
BWA=`which bwa`;
CAT=`which cat`;
GZIP=`which gzip`;
GREP=`which grep`;
MKDIR=`which mkdir`;
TOUCH=`which touch`;
SAMTOOLS=`which samtools`;
FASTQMCF=`which fastq-mcf`;
JAVA=`which java`;

### convenience functions
function reportf () { 
    printf "[%s] " `basename $0` >&2;
    printf "$1" >&2;
}

function depend () { 
    printf "[%s] ERROR: " `basename $0` >&2;
    echo "$1: dependencies incomplete, an upstream step likely did not finish." >&2;
    exit 2;
}

function error () {
    printf "[%s] ERROR: " `basename $0` >&2;
    echo "$2." >&2;
    exit $1;
}

function validateManifest () {
    if [[ -z "$1" ]]; then
	usage; error 2 "No manifest given";
    else
	${CAT} $1 | ${GREP} -v '^#' | while read r; do 
	    if [[ -z "$r" || ! -f "$r" ]]; then
		error 2 "SE file not defined or does not exist: $r";
	    fi
	done
    fi
}


function usage () {
    printf "\n" >&2;
    printf "Usage: %s [--workdir <dir_path>] [--target-analysis <dir_path>]\n" `basename $0` >&2;
    printf "        [--datadir <dir_path>] [--sample-file <sample_file>]\n" >&2;
    printf "        [--adaptor-fasta <adaptor_fasta>] [--ref-genome <genome_fasta>]\n" >&2;
    printf "        [--lib-name <library_name>] [--sequence-source <sequence_source>]\n" >&2;
    printf "        [--flowcell-id <seqrun_fcid>] [--flowcell-lane <seqrun_lane>]\n" >&2;
    printf "        [--manifest <fastq_manifest>] [--max-runtime <HH:MM:SS>]\n" >&2;
    printf "        [--help] [-help] [-h]\n" >&2;
    printf "\n" >&2;
    printf "Notes:\n\n" >&2;
    printf "  1. This script assumes a standard UNIX/Linux install with the addition\n" >&2;
    printf "     of a few bioinformatics tools: samtools, bwa, ea-utils, and the\n" >&2;
    printf "     gbs-analysis repo (20140204+). All external tools must be accessible\n" >&2;
    printf "     from the user\'s PATH, and the target-analysis dir absolute path given by\n" >&2;
    printf "     its flag (above). In addition, this script assumes access to an SGE\n" >&2;
    printf "     job-scheduling system that can be accessed by \`qsub\'.\n\n" >&2;
    printf "  2. All arguments are required.\n\n" >&2;
    printf "  3. It is highly recommended that absolute paths be passed via the required\n" >&2;
    printf "     flags, as those paths may be used in a submission to the cluster.\n\n" >&2;
    printf "  4. A separate working directory should be created for each run/analysis,\n" >&2;
    printf "     as each run uses touch files to track the progress of the pipeline and\n" >&2;
    printf "     launching multiple runs in the same directory may cause one run to\n" >&2;
    printf "     interfere with the proper execution of others.\n\n" >&2;
    printf "\n\n" >&2;
}

COMMAND="$0 $*";

## RETRIEVE THE OPTIONS ON THE COMMAND-LINE (THESE OVER-RIDE HARD-CODED):
HELP_MESSAGE=;
while [[ -n $@ ]]; do
    case "$1" in
	'--lib-name') shift; LIBNAME=$1;;
	'--ref-genome') shift; GENOME=$1;;
	'--workdir') shift; WORKDIR=$1;;
	'--datadir') shift; DATADIR=$1;;
	'--max-runtime') shift; RUNTIME=$1;;
	'--target-analysis') shift; TARGETTOOL=$1;;
	'--sample-file') shift; SAMPLE=$1;;
	'--adaptor-fasta') shift; ADAPTOR=$1;;
	'--sequence-source') shift; SOURCE=$1;;
	'--flowcell-id') shift; FCID=$1;;
	'--flowcell-lane') shift; LANE=$1;;
	'--manifest') shift; MANIFEST=$1;;
	'--help') HELP_MESSAGE=1;;
	'-h') HELP_MESSAGE=1;;
	-*) usage; error 2 "Invalid option: ${1}";;
	*) break;;
    esac;
    shift;
done

###############################################################################
# Data QC:
###############################################################################
if [[ -n "${HELP_MESSAGE}" ]]; then
    usage;
    exit 1;

elif [[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]]; then
    usage; error 1 "WORKDIR not defined or does not exist";

elif [[ -z "${DATADIR}" || ! -d "${DATADIR}" ]]; then
    usage; error 1 "DATADIR not defined or does not exist";

elif [[ -z "${TARGETTOOL}" || ! -d "${TARGETTOOL}" ]]; then
    usage; error 1 "TARGETTOOL not defined or does not exist";

elif [[ -z "${GENOME}" || ! -f "${GENOME}" ]]; then
    usage; error 1 "GENOME not defined or does not exist";

elif [[ -z "${SAMPLE}" || ! -f "${SAMPLE}" ]]; then
    usage; error 1 "SAMPLE not defined or does not exist";

elif [[ -z "${ADAPTOR}" || ! -f "${ADAPTOR}" ]]; then
    usage; error 1 "ADAPTOR not defined or does not exist";

elif [[ -z "${MANIFEST}" || ! -f "${MANIFEST}" ]]; then
    usage; error 1 "MANIFEST not defined or does not exist";

elif [ -z "${SOURCE}" ]; then
    usage; error 1 "SOURCE not defined";

elif [ -z "${LIBNAME}" ]; then
    usage; error 1 "LIBNAME not defined";

elif [ -z "${FCID}" ]; then
    usage; error 1 "FCID not defined";

elif [ -z "${LANE}" ]; then
    usage; error 1 "LANE not defined";

else
    printf "[%s] Starting %s %s %s %s %s %s\n" `basename $0` `date`   >&2;
    printf "[%s] Command-line: $COMMAND\n" `basename $0` >&2;
 #   printf "[%s] PARAM: %s = %s\n" `basename $0` "LIBNAME"  $LIBNAME >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "SEQRUN"   $SEQRUN   >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "SOURCE"   $SOURCE   >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "FCID"     $FCID     >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "LANE"     $LANE     >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "WORKDIR"  $WORKDIR  >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "DATADIR"  $DATADIR  >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "MANIFEST" $MANIFEST >&2;    
    printf "[%s] PARAM: %s = %s\n" `basename $0` "GENOME"   $GENOME   >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "SAMPLE"  $SAMPLE  >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "ADAPTOR"  $ADAPTOR  >&2;
    printf "[%s] PARAM: %s = %s\n" `basename $0` "TARGETTOOL"  $TARGETTOOL  >&2;
fi

if [[ -z "${SAMTOOLS}" || ! -x "${SAMTOOLS}" ]]; then
    error 127 "samtools not in PATH env variable or not executable";

elif [[ -z "${BWA}" || ! -x "${BWA}" ]]; then
    error 127 "bwa not in PATH env variable or not executable";

elif [[ -z "${FASTQMCF}" || ! -x "${FASTQMCF}" ]]; then
    error 127 "fastq-mcf not in PATH env variable or not executable";

elif [[ -z "${GZIP}" || ! -x "${GZIP}" ]]; then
    error 127 "gzip not in PATH env variable or not executable";

elif [[ -z "${GREP}" || ! -x "${GREP}" ]]; then
    error 127 "grep not in PATH env variable or not executable";

elif [[ -z "${CAT}" || ! -x "${CAT}" ]]; then
    error 127 "cat not in PATH env variable or not executable";

elif [[ -z "${MKDIR}" || ! -x "${MKDIR}" ]]; then
    error 127 "mkdir not in PATH env variable or not executable";

elif [[ -z "${TOUCH}" || ! -x "${TOUCH}" ]]; then
    error 127 "touch not in PATH env variable or not executable";

elif [[ -z "${JAVA}" || ! -x "${JAVA}" ]]; then
    error 127 "java not in PATH env variable or is not executable";

elif [[ -z "${PICARD}" ]]; then
    error 127 "picard.jar not in env variable";
fi

# Check that external tools are accessible:
DATE=`date +%F`;
PATH=$TARGETLIB/scripts:$PATH
PERL5LIB=$TARGETLIB/lib:$PERL5LIB


validateManifest $MANIFEST;

# create fasta index (if necessary)
reportf "faidx index: ";
if [[ ! -s "$GENOME.fai" || "$GENOME.fai" -ot "$GENOME" ]]; then
    echo "executing" >&2;
    ${SAMTOOLS} faidx ${GENOME} || error 2 "Unable to create faidx index";
else
    echo "current" >&2;
fi

# create dictionary file (if necessary)
genomedir=`dirname $GENOME`
dicname=`basename $GENOME .fasta`
reportf "dictionary file: ";
if [[ ! -s "${genomedir}/${dicname}.dict" ]]; then
    echo "executing" >&2;
    java -jar ${PICARD} CreateSequenceDictionary R=${GENOME} O=${genomedir}/${dicname}.dict || error 2 "Unable to create faidx index";
else
    echo "current" >&2;
fi



# create Burrows-Wheeler index (if necessary)
reportf "BWT index: ";
if [[ ! -s "$GENOME.bwt" || "$GENOME.bwt" -ot "$GENOME" ]]; then
    echo "executing" >&2;
    ${BWA} index ${GENOME} || error 2 "Unable to create bwt index";
else
    echo "current" >&2;
fi


# trim adapters
# ============================================================
reportf "Adaptor trimming: ";
if [[ ! -e "${WORKDIR}/fastqmcf.complete" ]]; then
    echo "executing" >&2;

    [ -d "${WORKDIR}/fastqmcf" ] || ${MKDIR} ${WORKDIR}/fastqmcf;

    for f in ${DATADIR}/${LIBNAME}/${LIBNAME}-*_0.fastq.gz; do
    	fo=`basename $f | sed 's/_0.fastq.gz/_xAd_0.fastq.gz/'`;
    	echo "${FASTQMCF} -U -f -t 0.0 -m 8 -l 35 -o ${WORKDIR}/fastqmcf/$fo ${ADAPTOR} $f";
    done >${WORKDIR}/fastqmcf.batch && \
	${TARGETTOOL}/scripts/qbatch submit -n fastqmcf-${LIBNAME} -q normal.c -Wj -R 1 -t ${RUNTIME} ${WORKDIR}/fastqmcf.batch && \
     	${TOUCH} ${WORKDIR}/fastqmcf.complete;
else
    echo "current" >&2;
fi


###############################################################################
# Alignment
###############################################################################

# align with BWA
# ============================================================
# the following pattern should work, but if you pre-trimmed use 
# *_xAd_[12]_0001.fastq.gz instead
# ------------------------------------------------------------
# use 'bwa sampe' command to enable paired-end read information (if applicable)
# or use the 'bwa samse' for single-end reads
# The -r argument, defining the read-group (@RG) line, is required downstream.
# @RG ID tags must be unique within the output BAM file, but the SM tags 
# may be the same (unique for each sample/individual). 
# ------------------------------------------------------------
reportf "Alignment: "
if [[ ! -e "${WORKDIR}/bwa.complete" ]]; then
    echo "executing" >&2;

    [ -d "${WORKDIR}/bwa" ] || ${MKDIR} ${WORKDIR}/bwa;

    reportf "Alignment bwa aln: ";
    if [[ ! -e "${WORKDIR}/bwa/aln.complete" ]]; then
	echo "executing" >&2;

	if [[ ! -e "${WORKDIR}/fastqmcf.complete" ]]; then
	    depend "Alignment";
	fi

	[ -d "${WORKDIR}/bwa/aln" ] || ${MKDIR} ${WORKDIR}/bwa/aln;

	for f in ${WORKDIR}/fastqmcf/*_xAd_0.fastq.gz; do 
	    o=`basename $f | sed 's/fastq.gz/sai/'`;
	    echo "${BWA} aln -q 10 -f ${WORKDIR}/bwa/aln/$o ${GENOME} $f";
	done >${WORKDIR}/bwaaln.batch && \
	    ${TARGETTOOL}/scripts/qbatch submit -n bwaaln-${LIBNAME} -q normal.c -Wj -R 1 -t ${RUNTIME} ${WORKDIR}/bwaaln.batch && \
     	    ${TOUCH} ${WORKDIR}/bwa/aln.complete;
    else
	echo "current" >&2;
    fi

    reportf "Alignment bwa samse: ";
    if [[ ! -e "${WORKDIR}/bwa/samse.complete" ]]; then
	echo "executing" >&2;

	if [[ ! -e "${WORKDIR}/bwa/aln.complete" ]]; then
	    depend "Alignment";
	fi

	printf "@HD\tVN:1.3\tSO:coordinate\n" >${WORKDIR}/bwa/hdr; 
	cat ${SAMPLE} | ${GREP} -v '^#' | while read rgsm sample; do
	    base="${LIBNAME}-${sample}_xAd";
	    rgid="${FCID}-${LANE}-${rgsm}";
	    ffnq="${WORKDIR}/fastqmcf/${base}_0.fastq.gz";
	    fsai="${WORKDIR}/bwa/aln/${base}_0.sai";      
	    obam="${WORKDIR}/bwa/${base}Q10.bam";
	    echo "${BWA} samse -r \"@RG\\tID:${rgid}\\tSM:${sample}\\tLB:${LIBNAME}\\tLI:${sample}\\tSB:${FCID}\\tSL:${LANE}\\tOR:FR\\tPL:ILLUMINA\\tCN:${SOURCE}\\tDT:${DATE}\" ${GENOME} $fsai $ffnq | ${CAT} ${WORKDIR}/bwa/hdr - | ${SAMTOOLS} view -bS - >$obam";
	done >${WORKDIR}/bwasamse.batch && \
	    ${TARGETTOOL}/scripts/qbatch submit -n bwasamse-${LIBNAME} -q normal.c -Wj -R 1 -t ${RUNTIME} ${WORKDIR}/bwasamse.batch && \
     	    ${TOUCH} ${WORKDIR}/bwa/samse.complete;

	# verify that BAMs are complete (have BAM headers + EOF markers).
	# If no errors are reported, all BAM files are complete.
	# ------------------------------------------------------------
	for f in ${WORKDIR}/bwa/*.bam; do
	    printf "[%s] BAM validation: %s\n" `basename $0` `basename $f` >&2;
	    ${SAMTOOLS} view -H $f | head -1 >/dev/null;
	done

    else
	echo "current" >&2;
    fi
    
    if [[ -e "${WORKDIR}/bwa/aln.complete" && -e "${WORKDIR}/bwa/samse.complete" ]]; then
	${TOUCH} ${WORKDIR}/bwa.complete;
    fi

else
    echo "current" >&2;
fi


# sort the alignments by coordinate
# ============================================================
# sort each bam with 5G (5369000000 bytes) memory limit for each thread (modify
# if necessary, default is 500MB)
# ------------------------------------------------------------
reportf "BAM sort: ";
if [[ ! -e "${WORKDIR}/sort.complete" ]]; then
    echo "executing" >&2;
    
    if [[ ! -e "${WORKDIR}/bwa.complete" ]]; then
	depend "BAM sort";
    fi

    [ -d "${WORKDIR}/sort" ] || ${MKDIR} ${WORKDIR}/sort

    for f in ${WORKDIR}/bwa/*.bam; do
	p=`basename $f | sed 's/bam/srt/'`;
	echo "${SAMTOOLS} sort -m 5G $f ${WORKDIR}/sort/$p";
    done >${WORKDIR}/sort.batch && \
	${TARGETTOOL}/scripts/qbatch submit -n sort-${LIBNAME} -q normal.c -Wj -R 6 -t ${RUNTIME} ${WORKDIR}/sort.batch && \
     	${TOUCH} ${WORKDIR}/sort.complete;

    for f in ${WORKDIR}/sort/*.srt.bam; do
	printf "[%s] BAM validation: %s\n" `basename $0` `basename $f` >&2;
	${SAMTOOLS} view -H $f | head -1 >/dev/null;
    done
else
    echo "current" >&2;
fi


# Produce a BAM index of each file for random access:
# ============================================================
reportf "BAM index: ";
if [[ ! -e "${WORKDIR}/index.complete" ]]; then
    echo "executing" >&2;
    
    if [[ ! -e "${WORKDIR}/sort.complete" ]]; then
	depend "BAM index";
    fi

    REPBAM=`\ls -1 ${WORKDIR}/sort/*.srt.bam | head -1`;
    if [ -z "${REPBAM}" ]; then
	error 2 "No BAM files present in ${WORKDIR}/sort";
    fi
    
    for f in ${WORKDIR}/sort/*.srt.bam; do
	echo "${SAMTOOLS} index $f"; 
    done >${WORKDIR}/index.batch && \
	${TARGETTOOL}/scripts/qbatch submit -n index-${LIBNAME} -q normal.c -Wj -R 6 -t ${RUNTIME} ${WORKDIR}/index.batch && \
	${TOUCH} ${WORKDIR}/index.complete;
else
    echo "current" >&2;
fi

# We now have BAM files containing reads from each individuals

# Produce a multi-sample BAM file:
# ============================================================
reportf "BAM merge: ";
if [[ ! -e "${WORKDIR}/merge.complete" ]]; then
    echo "executing" >&2;
    
    if [[ ! -e "${WORKDIR}/sort.complete" ]]; then
	depend "BAM merge";
    fi

    REPBAM=`\ls -1 ${WORKDIR}/sort/*.srt.bam | head -1`;
    if [ -z "${REPBAM}" ]; then
	error 2 "No BAM files present in ${WORKDIR}/sort";
    fi
    ${SAMTOOLS} view -H ${REPBAM} | ${GREP} -v '^@RG' >${WORKDIR}/sort/hdr;

    
    # append read-group (@RG) lines for each library
    # ------------------------------------------------------------
    for f in ${WORKDIR}/sort/*.srt.bam; do
	${SAMTOOLS} view -H $f | ${GREP} '^@RG'; 
    done >>${WORKDIR}/sort/hdr && \
	${SAMTOOLS} merge -f -h ${WORKDIR}/sort/hdr \
	${WORKDIR}/${LIBNAME}_${FCID}_${LANE}_xAdQ10.srt.bam \
	${WORKDIR}/sort/*.srt.bam && \
	${TOUCH} ${WORKDIR}/merge.complete;
else
    echo "current" >&2;
fi


# Index the BAM for random access:
# ============================================================
reportf "Merged BAM index: ";
if [[ ! -s "${WORKDIR}/${LIBNAME}_${FCID}_${LANE}_xAdQ10.srt.bam" || \
    "${WORKDIR}/${LIBNAME}_${FCID}_${LANE}_xAdQ10.srt.bam.bai" -ot \
    "${WORKDIR}/${LIBNAME}_${FCID}_${LANE}_xAdQ10.srt.bam" ]]; then
    echo "executing" >&2;

    if [[ ! -e "${WORKDIR}/merge.complete" ]]; then
	depend  "Merged BAM index";
    fi

    ${SAMTOOLS} index ${WORKDIR}/${LIBNAME}_${FCID}_${LANE}_xAdQ10.srt.bam && \
	${TOUCH} ${WORKDIR}/indexmerge.complete
else
    echo "current" >&2;
fi

# We now have a single BAM file containing all reads from all individuals,
# and each read knows from which sample/barcode it came



printf "[%s] Finished %s %s %s %s %s %s\n" `basename $0` `date` >&2;

exit 0;
