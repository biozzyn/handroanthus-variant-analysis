#!/bin/bash
#$ -w e
#$ -cwd
#$ -t 1

WORKDIR=""    #need to setup; see README.md
GENOME=""     #need to setup; see README.md

[ -d "${WORKDIR}/genotyping" ] || mkdir ${WORKDIR}/genotyping;

declare -A SAMPLE
SAMPLE[1]=HIMP

spp=${SAMPLE[${SGE_TASK_ID}]}

for bam in $(ls -1 ${WORKDIR}/*/*_xAdQ10.srt.bam)
do
 bams+=" -I ${bam} "
done

java -jar -Xmx5g -Xms5g ${GATK} \
  -T VariantFiltration \
  -R $GENOME \
  -V ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.vcf \
  -G_filter "GQ < 20.0" -G_filterName lowGQ \
  --setFilteredGtToNocall \
  -o ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.vcf

#remove sites that is monomorphic or has no data after GQ filtering
vcftools --vcf ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.vcf \
  --out ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.vcf \
  --mac 2 --min-alleles 2 --max-alleles 2 \
  --recode --recode-INFO-all --stdout > ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.vcf

java -jar $SNPEFF \
  ann \
  -i vcf \
  -noStats \
  -csvStats ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.eff.stats.csv \
  -o gatk \
  him \
  ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.vcf \
  >${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.eff.vcf


java -jar -Xmx5g -Xms5g ${GATK} \
  -T VariantAnnotator \
  -R $GENOME \
  -V ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.vcf \
  -all \
  -L ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.vcf \
  -o ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.annot.vcf \
   --snpEffFile ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.eff.vcf \
  -XA MVLikelihoodRatio \
  -XA PossibleDeNovo \
  -XA DepthPerSampleHC \
  -XA AS_RMSMappingQuality \
  -XA ClusteredReadPosition \
  -XA TransmissionDisequilibriumTest \
  $bams

grep -v '^#' ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.f.annot.vcf | \
cut -f 1,2,7 | \
bgzip -c > ${WORKDIR}/genotyping/variant_status.tab.gz

tabix -s1 -b2 -e2 ${WORKDIR}/genotyping/variant_status.tab.gz

echo "##INFO=<ID=RECAL_STATUS,Number=1,Type=String,Description=\"Status of the variant after applying Variant Recalibrator Tool\">" \
>${WORKDIR}/genotyping/variant_status.hdr


/lbi/acgt/bioinfo/GENOME_MAPPING/SAMTOOLS/bcftools-1.1/bcftools annotate \
  -a ${WORKDIR}/genotyping/variant_status.tab.gz \
  -h ${WORKDIR}/genotyping/variant_status.hdr \
  -c CHROM,POS,RECAL_STATUS \
  ${WORKDIR}/genotyping/HIMP.SNPS.recal_ts90.0.xGQ20.f.annot.vcf \
  >${WORKDIR}/genotyping/HIMP.SNPS.recal_ts90.0.xGQ20.annotated.vcf 

vcftools --vcf ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.annotated.vcf \
  --out ${WORKDIR}/genotyping/${spp}.SNPS.filtered \
  --max-missing 0.8 \
  --remove-filtered-all \
  --recode --recode-INFO-all --stdout > ${WORKDIR}/genotyping/${spp}.SNPS.filtered.vcf


ann=$( grep '^##INFO' ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.annotated.vcf | \
      awk -F"," '{sub("##INFO=<ID=","",$1); printf " --get-INFO %s ", $1} END {printf "\n"}' )


vcftools --vcf ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.annotated.vcf \
  --out ${WORKDIR}/genotyping/${spp}.SNPS.recal_ts90.0.xGQ20.annotated.metrics \
  $ann
