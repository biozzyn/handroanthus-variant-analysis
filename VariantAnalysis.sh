#!/bin/bash
#$ -w e
#$ -cwd 
#$ -t 1-24

## NEED TO BE MODIFIED BY THE ANALYST
WORKDIR="<path-to-analysis>"                                          #need to setup; see README.md
GENOME="<absolute-path-to-genome>/genome.fasta"                       #need to setup; see README.md
PROBESET="<path-to-analysis>/share/Himpetiginosus.probeset.v0.3.bed"  #need to setup; see README.md
##

ID=$SGE_TASK_ID

[ -d "${WORKDIR}/gatk" ] || mkdir ${WORKDIR}/gatk;

samples=$(cat ${WORKDIR}/*/samples.tsv | cut -f 2 | sort -u )

i=1

declare -A SNAME
for sample in $samples;
do
 SNAME[$i]=$sample
 i=$((i+1))
done


java -jar -Xmx5g -Xms5g ${GATK} \
 -T HaplotypeCaller \
 -mmq 10 \
 -mbq 10 \
 -I ${WORKDIR}/HIMP-1/sort/HIMP1_1-${SNAME[${ID}]}_xAdQ10.srt.bam \
 -I ${WORKDIR}/HIMP-2/sort/HIMP2_1-${SNAME[${ID}]}_xAdQ10.srt.bam \
 -o ${WORKDIR}/gatk/${SNAME[${ID}]}.g.vcf \
 -R $GENOME \
 -ERC GVCF \
 --heterozygosity 0.015 \
 -L ${PROBESET} \
 --variant_index_type LINEAR --variant_index_parameter 128000
