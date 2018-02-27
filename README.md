# Purpose

Targeted sequence capture coupled to high-throughput sequencing has become a powerful method for the study of genome-wide sequence variation in non-model genomes. 

Following the recent availability of a genome sequence assembly for the Pink Ipê tree (*Handroanthus impetiginosus*) that appeared in GigaScience Jounal (2018), we reported the development of a set of 24,751 capture probes for single nucleotide polymorphisms (SNPs) characterization and genotyping across 18,216 distinct loci, sampling more than 10 Mbp of the species genome. This system identifies nearly 200,000 SNPs located inside or in close proximity to almost 14,000 annotated protein-coding genes, generating quality genotypic data in populations spanning wide geographic distances across the species native range.

This is the project containing all scripts used in the analyses developed for the "Design and evaluation of a sequence capture system for genome-wide SNP genotyping of a keystone Neotropical hardwood tree genome" paper now accepted an to be published in the Jounal DNA Research (2018). The pipeline uses standard tools for variant analysis distributed under specific Open Source Licenses. It takes fastq data generated using RAPiD Genomics (Gainsville, Florida, USA)' Capture-Seq service and the genome assembly sequence of *Handroanthus impetiginosus* as primary inputs. All data are available from NCBI's publicly repositories. 

Briefly, the pipeline guides the user through the following analysis:

```
1. Fastq adaptor- and quality-trimming
2. Short-read alignment
3. Variant calling and genotyping
4. Variant filtration
5. Variant annotation
```

The pipeline relies on the use of a distributed memory compute cluster to enable the analyst to run large scale project with  large number of samples.

Analysis 1 & 2 are perfomed in an automated way with a modified version of the scripts provided by the International Cassava Genetic Map Consortium (ICGMC) paper published in [G3 Journal (2015)](https://doi.org/10.1534/g3.114.015008). Scripts were originally written for processing Illumina paired-end data or Illumina single-read data and use BWA to align reads against the input reference genome sequence.

Analyses 3 - 5 are perfomed manually and the analyst should consult the Variant Calling and Genotyping section provided herein for step-by-step analysis instructions. Tips on assessing data quality and choosing thresholds are provided in the supplementary file S1 of the manuscript.

# Getting Started

Included pipeline scripts require a successful install of various open-source tools used for variant analysis. See Dependencies herein. Additionaly, the analyst will need to install the scripts provided by the International Cassava Genetic Map Consortium (ICGMC) available [here](https://bitbucket.org/rokhsar-lab/gbs-analysis).

## Prerequisites

Please see the **Installation section** of [IGGMC](https://bitbucket.org/rokhsar-lab/gbs-analysis) repository to get information on how to obtain the necessary code and configure your local system to run analysis 1 & 2 in this pipeline. For the analyses 3 - 5 the pipeline requires the installation of GATK and associated programs.

The analyst should observe that all the required programs have to be accessible via the user's PATH environment variable. For the GATK, SNPEff, PICARD programs we used the following entries in our Bash startup file ``.bashrc``

```
GATK="~/my_tools/gatk/GenomeAnalysisTK.jar"
PICARD="~/my_tools/picard/picard.jar"
SnpEff="~/my_tools/snpeff/snpEff.jar"
```

So then when you want to run a Picard/GATK/SnpEff tool, you just need to call the jar by its shortcut, like this:

```
java -jar $GATK -T <Toolname> [options]
java -jar $PICARD <Toolname> [options]
java -jar $SnpEff <Toolname> [options]
```

More detailed information on how to setup necessary programs to run a variant analysis pipeline using GATK is accessible [here](https://gatkforums.broadinstitute.org/gatk/discussion/2899/howto-install-all-software-packages-required-to-follow-the-gatk-best-practices)

## Installation

### Obtaining the code

Create a directory to clone the project files into. Remember that this directory should be accessible to your local cluster environment. For example:

```
cd <path-to-your-local-install>
```
Assuming Git is correctly installed on your system, simply invoke:

```
git clone https://github.com/biozzyn/handroanthus-variant-analysis.git
```
The directory ``<path-to-your-local-install>/handroanthus-variant-analysis`` will be referred hereafter as ``<path-to-project-install>``

## Configuring your installation

Assuming all the required dependencies are successfully installed in your local system you can proceed to download the data used as input for the pipeline.

### Data directory structure

Under the project structure there is a directory named ``data``. The analyst shoud copy the content of the directory to a local acessible to the cluster system and run the ``setup.sh`` to initiate the download of the fastq from the NCBI's SRA repo

```
mkdir <absolute-path-to-data>
cd <path-to-project-install>
cp -r data/* <absolute-path-to-data>/
cd <absolute-path-to-data>
bash setup.sh
```
This setup script uses the program ``fastq-dump`` whithin the NCBI SRA Toolkit package to download the fastq files for the experiments. It creates a recommended directory structure that is arranged hierarchically with the read files sequence within it. For example:

```
<absolute-path-to-data>/
          <LIBRARY-NAME>_<RUN-ID>/
                 <LIBRARY-NAME>_<RUN-ID>-<SAMPLE-NAME>_0.fastq.gz
```

In our manuscript we described a first Capture-Seq library using fragments of DNA captured by 30,795 probes in the sample of 24 individuals of H. impetiginosus. These fragments were sequenced in a single sequencing run in one lane of a HiSeq2000 instrument, single-end mode. These sequence data will be available within a directory named HIMP1_1.

We described also a second Capture-Seq library for a partially replicate set using fragments of DNA captured by 14,135 probes out of the original set of 30,795 probeset.These fragments were sequenced in a single sequencing run in one lane of a HiSeq2000 instrument, single-end mode. These sequence data will be available within a directory named HIMP2_1.

After this step is completed two new directories ``HIMP1_1`` and ``HIMP2_1`` should be created each one containing 24 fastq files named as above.

### Sequence assembly

Under the project structure there is a directory named ``genome``. The analyst shoud copy the content of the directory to a local acessible to the cluster system and run the ``setup.sh`` to initiate the download of the multi-fasta from the NCBI's Genbank repo.

```
mkdir <absolute-path-to-genome>
cp -r genome/* <absolute-path-to-genome>
cd <absolute-path-to-genome>
bash setup.sh
```

This setup script uses ``wget`` program to download the sequence assembly and modify the sequence header for further processing. There should be a file named ``genome.fasta`` after this step is completed.

## Analysis directory structure

The analysist is recommended to create a directory for the analysis. It should be noted that this directory must be accessible to the cluster. It will encompass all the intermediate files generated by the pipeline, including preprocessed reads and alignment files. This directory will be named ``$WORKDIR`` in the pipeline.

```
mkdir <path-to-analysis>
```

### Additional resources

Additional resources used by the pipeline are available to the analyst under the directory ``share`` in this project. Basically, it includes reference information about reliable SNPs for quality score recalibration using GATK VariantRecalibrator tool and also a reference database of SNP annotations generated using the SNPEff program. Detailed description on how these resources were generated is provided in the ``supplementary file S1 of the manuscript``.

The shared resources should be available to the pipeline in the directory set up for the analysis

```
cp -r <path-to-project-install>/share <path-to-analysis>/
cd <path-to-analysis>/share
gunzip *.gz
```

To successful run the variant annotation step, the analysit should configure a new database entry for the SNPEff program. In our pipeline we called this database ``him``. To add a new genome to SNPEff the analyst can consult information [here](http://snpeff.sourceforge.net/SnpEff_manual.html#buildAddConfig). After adding the new entry for the genome of *Handroanthus impetiginousus*

```
mkdir /path/to/snpEff/data/him
cp <path-to-project-install>/share/snpEffectPredictor.bin /path/to/snpEff/data/him/
```

## Running the pipeline

To run the pipeline, the analyst should create a directory for the analysis. This directory should be accessible to the cluster. After that copy the whole directories HIMP-1 and HIMP-2 under the project files.

```
cd <path-to-analysis>
cp -r <path-to-project-install>/HIMP-1 <path-to-analysis>/
cp -r <path-to-project-install>/HIMP-2 <path-to-analysis>/
```

The analysist should prepare the manifest file ``manifest.txt`` to reflect the actual placement of the input fastq. For example:

```
ls -1 <absolute-path-to-data>/HIMP1_1/*.fastq.gz > <path-to-analysis>/HIMP-1/manifest.txt
ls -1 <absolute-path-to-data>/HIMP2_1/*.fastq.gz > <path-to-analysis>/HIMP-2/manifest.txt
```

### Preprocessing (automated step using [IGGMC](https://bitbucket.org/rokhsar-lab/gbs-analysis))

To execute steps 1 & 2 in the pipeline, run:

For the library/run HIMP1_1:

```
<path-to-project-install>/preprocessingSE.sh \
  --workdir <path-to-analysis>/HIMP-1 \
  --datadir <absolute-path-to-data> \
  --lib-name HIMP1_1 \
  --sample-file <path-to-analysis>/HIMP-1/samples.tsv \
  --manifest <path-to-analysis>/HIMP-1//manifest.txt \
  --target-analysis <path-to-IGGMC-analysis-tool> \
  --adaptor-fasta <path-to-analysis>/share/adaptors_illumina.fa \
  --ref-genome <absolute-path-to-genome>/genome.fasta \
  --sequence-source Handroanthus_impetiginosus \
  --flowcell-id C2THMACXX \
  --flowcell-lane 2 \
  --max-runtime 08:00:00 >& himp1_1.prepro.log &
```

For the library/run HIMP2_1:

```
<path-to-project-install>/preprocessingSE.sh \
  --workdir <path-to-analysis>/HIMP-2 \
  --datadir <absolute-path-to-data> \
  --lib-name HIMP2_1 \
  --sample-file <path-to-analysis>/HIMP-2/samples.tsv \
  --manifest <path-to-analysis>/HIMP-2/manifest.txt \
  --target-analysis <path-to-IGGMC-analysis-tool> \
  --adaptor-fasta <path-to-analysis>/share/adaptors_illumina.fa \
  --ref-genome <absolute-path-to-genome>/genome.fasta \
  --sequence-source Handroanthus_impetiginosus \
  --flowcell-id C2Y14ACXX \
  --flowcell-lane 6 \
  --max-runtime 08:00:00 >& himp2_1.prepro.log &
```

If all the analysis ran successfully the analysist shoud find BAM formatted files under the ``<path-to-analysis>/HIMP-1`` and ``<path-to-analysis>/HIMP-2`` directories. These files contain the read to genome alignments that should be used as input to the variant analysis steps in the pipeline.

### Variant Calling and Genotyping (performed manually)

This step in the pipeline is performed by the script ``VariantCalling.sh``.

The absolute paths of the input data are hardcoded in this script and should be adjusted by the analyst before execution.

```
WORKDIR="<path-to-analysis>"
GENOME="<absolute-path-to-genome>/genome.fasta"
PROBESET="<path-to-analysis>/share/Himpetiginosus.probeset.v0.3.bed"
```
Use qsub program to submit the job script to the cluster

```
qsub -N variant-calling -q normal.c <path-to-project-install>/VariantAnalysis.sh
```

Basically, this script will perform the variant call step in the pipeline using GATK's HaplotypeCaller model. It takes the alignment files and produce raw (unfiltered) gVCF files for each processed sample over the target intervals ``(file: $PROBESET)``. Details on how we have determined the basic parameters of the analysis are described in the main text (Results and Discussion) and supplementary file S1 of the manuscript.

Note that if you are using GATK version older than 3.4 you need to set the appropriate values  for --variant_index_type and --variant_index_parameter. For caution we set these parameter in the script.

### Variant Genotyping (performed manually)

This step in the pipeline is performed by the script ``GenotypingAnalysis.sh``.

The absolute paths of the input data are hardcoded in this script and should be adjusted by the analysist before execution.

```
WORKDIR="<path-to-analysis>"
GENOME="<absolute-path-to-genome>/genome.fasta"
PROBESET="<path-to-project-install>/share/Himpetiginosus.probeset.v0.3.bed"
```
Use qsub program to submit the job script to the cluster

```
qsub -N variant-genotyping -q normal.c <path-to-project-install>/GenotypingAnalysis.sh
```

This step uses GATK's GenotypeGVCFs to merge gVCF records that were produced as part of the Best Practices workflow for variant discovery using the '-ERC GVCF' mode of the HaplotypeCaller. This tool performs the multi-sample joint aggregation step and merges the records together: at each position of the input gVCFs, GenotypeGVCFs will combine all spanning records to produce correct genotype likelihoods.

Additionaly, GATK's VariantRecalibrator tool is used to assign a well-calibrated probability to each variant call in the raw call set. The approach taken by this tools is to develop a continuous, covarying estimate of the relationship between SNP call annotations (QD, MQ, MQRankSum, ReadPosRankSum and FS were used) and the probability that a SNP is a true genetic variant versus a sequencing or data processing artifact. This model is determined adaptively based on "true sites" provided as input in the ``<path-to-analysis>/share/vqsr_truth-true_training-yes.vcf`` and ``<path-to-analysis>/share/vqsr_truth-true_training-yes.vcf``. Details on how we have determined these "true sites" parameters of the analysis are described in the supplementary file S1 of the manuscript.

### Variant Filtration and Annotation (performed manually)

This step in the pipeline is performed by the script ``VariantAnnotation.sh``.

The absolute paths of the input data are hardcoded in this script and should be adjusted by the analysist before execution.

```
WORKDIR="<path-to-analysis>"
GENOME="<absolute-path-to-genome>/genome.fasta"
```
Use qsub program to submit the job script to the cluster

```
qsub -N variant-annotation -q normal.c <path-to-project-install>/VariantAnnoation.sh
```

This script perform additional refinement to the variant call and genotyping steps to remove unreliable genotype records (GQ < 20).  These filtered records are marked and set to no-call (./.)  using GATK's VariantFiltration tool. We only filter on GQ to disqualify variants where we have too few samples with reasonable-quality genotypes. After this step, we re-annotate each remaining variants using all available metrics provided by the GATK's VariantAnnotator tool and SNPEff program.

A final set of calls with genotypes is then provided to the analyst. This set contains the filtered calls where we have observed SNP call rate > 80% across the analysed sample of 24 individuals.


## Built With

### Gnu/Linux shell and utility softwares
* [Bash](https://www.gnu.org/software/bash/) - Bash is the GNU Project's shell. It is an sh-compatible shell that incorporates useful features from the Korn shell (ksh) and C shell (csh). It is intended to conform to the IEEE POSIX P1003.2/ISO 9945.2.
* wget, cut, cat, grep, gzip, mkdir and touch

### Sequence data gathering
* [NCBI SRA Toolkit](https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/) - The SRA Toolkit provides tools to download and access SRA data.

### Sequence data QC, Alignment and Processing
* [ICGMC](https://bitbucket.org/rokhsar-lab/gbs-analysis) - The International Cassava Genetic Map Consortium (ICGMC) Pipeline for preprocessing of Illumina-sequenced data.

### Variant and Genotype Calling/Annotation/Filtering
* [JAVA SE Development Kit](http://www.oracle.com/technetwork/pt/java/javase/index.html) -  The JDK includes tools useful for developing and testing programs written in the Java programming language and running on the Java platform.
* [GATK](https://software.broadinstitute.org/gatk/best-practices) - Genome Analysis Toolkit
Variant Discovery in High-Throughput Sequencing Data.
* [VCFtools](https://vcftools.github.io) - A set of tools written in Perl and C++ for working with VCF files.
* [Samtools/BCFtools](http://www.htslib.org) - A suite of programs for interacting with high-throughput sequencing data
* [SnpEff](http://snpeff.sourceforge.net) - Genomic variant annotations and functional effect prediction toolbox.

## Citation
* To appear in Silva-Junior OB, Novaes E, Grattapaglia D, Collevatti R. *Design and evaluation of a sequence capture system for genome-wide SNP genotyping of a keystone Neotropical hardwood tree genome*. DNA Research (2018).

## Authors

* **Orzenil B Silva-Junior** - *Github initial setup* - [biozzyn](https://github.com/biozzyn/handroanthus-variant-analysis)

## Acknowledgments

* We thank the anonymous reviewers for their careful reading of our manuscript and their insightful suggestions.

## Additional reading

Genome assembly of *Handroanthus impetiginosus*:

* Silva-Junior OB, Novaes E, Grattapaglia D, Collevatti R. Genome assembly of the Pink Ipê (Handroanthus impetiginosus, Bignoniaceae), a highly valued, ecologically keystone Neotropical timber forest tree. GigaScience, Volume 7, Issue 1, 1 January 2018, Pages 1–16. [link](https://doi.org/10.1093/gigascience/gix125)

Description of RAPiD Genomics (Gainsville, Florida, USA)' Capture-Seq can be found in:

* Neves LG, Davis JM, Barbazuk WB, Kirst M. Whole-exome targeted sequencing of the uncharacterized pine genome. The Plant Journal (2013) 75, 146–156. [link](http://dx.doi.org/10.1111/tpj.12193)

* http://www.rapid-genomics.com/wp-content/uploads/2014/05/Capture-Seq-RAPiD-Genomics.pdf
