#!/bin/bash
#$ -w e
#$ -cwd 
#$ -t 1-24

#see
#http://gatkforums.broadinstitute.org/gatk/discussion/5389/unusual-calls-after-using-haplotypecaller-filtered-with-vqsr-and-refinement-workflow

ID=$SGE_TASK_ID

WORKDIR=""    #need to setup; see README.md
GENOME=""     #need to setup; see README.md
PROBESET=""   #need to setup; see README.md

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
 -I ${WORKDIR}/HIMP-1/sort/HIMP_1-${SNAME[${ID}]}_xAdQ10.srt.bam \
 -I ${WORKDIR}/HIMP-2/sort/HIMP_2-${SNAME[${ID}]}_xAdQ10.srt.bam \
 -o ${WORKDIR}/gatk/${SNAME[${ID}]}.g.vcf \
 -R $GENOME \
 -ERC GVCF \
 --heterozygosity 0.015 \
 -L ${PROBESET} \
 --variant_index_type LINEAR --variant_index_parameter 128000
