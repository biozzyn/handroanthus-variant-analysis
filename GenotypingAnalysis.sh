#!/bin/bash
#$ -w e
#$ -cwd
#$ -t 1

## NEED TO BE MODIFIED BY THE ANALYST
WORKDIR="<path-to-analysis>"                                          #need to setup; see README.md
GENOME="<absolute-path-to-genome>/genome.fasta"                       #need to setup; see README.md
PROBESET="<path-to-analysis>/share/Himpetiginosus.probeset.v0.3.bed"  #need to setup; see README.md
##

[ -d "${WORKDIR}/genotyping" ] || mkdir ${WORKDIR}/genotyping;

declare -A SAMPLE
SAMPLE[1]=HIMP

spp=${SAMPLE[${SGE_TASK_ID}]}

thresh_mm=$(cat ${WORKDIR}/*/samples.tsv | cut -f 2 | sort -u | wc -l | awk '{ print ($1 * 2 - 1) }')

for gvcf in $(cat ${WORKDIR}/*/samples.tsv | cut -f 2 | sort -u)
do
 samples+=" --variant ${WORKDIR}/gatk/${gvcf}.g.vcf "
done

java -jar -Xmx5g -Xms5g ${GATK} \
  -T GenotypeGVCFs \
  -R ${GENOME} \
  --heterozygosity 0.015 \
  --max_alternate_alleles 12 \
  -L ${PROBESET} \
  -o ${WORKDIR}/genotyping/${spp}.raw.vcf \
  --variant_index_type LINEAR --variant_index_parameter 128000 \
  $samples

vcftools --vcf ${WORKDIR}/genotyping/${spp}.raw.vcf \
 --out ${WORKDIR}/genotyping/${spp}.SNPS.raw \
 --remove-indels --recode --recode-INFO-all \
 --stdout > ${WORKDIR}/genotyping/${spp}.SNPS.raw.vcf

java -jar -Xmx5g -Xms5g ${GATK} \
  -T VariantRecalibrator \
  -R $GENOME \
  -input ${WORKDIR}/genotyping/${spp}.SNPS.raw.vcf \
  -resource:himpbest,known=false,training=true,truth=true,prior=15.0 ${WORKDIR}/share/vqsr_truth-true_training-yes.vcf \
  -resource:himppoli,known=false,training=true,truth=false,prior=10.0 ${WORKDIR}/share/vqsr_truth-false_training-yes.vcf \
  -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS \
  -mode SNP \
  -recalFile ${WORKDIR}/genotyping/${spp}.recal \
  -tranchesFile ${WORKDIR}/genotyping/${spp}.tranches \
  -rscriptFile ${WORKDIR}/genotyping/${spp}.plots.R

java -jar -Xmx5g -Xms5g ${GATK} \
  -T ApplyRecalibration \
  -R $GENOME \
  -input ${WORKDIR}/genotyping/${spp}.SNPS.raw.vcf \
  -mode SNP \
  --ts_filter_level 90.0 \
  -recalFile  ${WORKDIR}/genotyping/${spp}.recal \
  -tranchesFile  ${WORKDIR}/genotyping/${spp}.tranches \
  -o  ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.vcf


#DEAL WITH INDELS
vcftools --vcf ${WORKDIR}/genotyping/${spp}.raw.vcf \
 --out ${WORKDIR}/genotyping/${spp}.INDELS.raw \
 --keep-only-indels --recode --recode-INFO-all \
 --stdout > ${WORKDIR}/genotyping/${spp}.INDELS.raw.vcf

#Apply Hard Filtering to INDELS

java -jar -Xmx5g -Xms5g ${GATK} \
  -T VariantFiltration \
  -R $GENOME \
  -V ${WORKDIR}/genotyping/${spp}.INDELS.raw.vcf \
  --filterExpression "QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0" \
  --filterName "indel_hardFilter" \
  -o ${WORKDIR}/genotyping/${spp}.INDELS.f.vcf

vcftools --vcf ${WORKDIR}/genotyping/${spp}.INDELS.f.vcf \
  --remove-filtered-all \
  --recode --recode-INFO-all \
  >${WORKDIR}/genotyping/${spp}.INDELS.filtered.vcf
