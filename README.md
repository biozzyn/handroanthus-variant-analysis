# Purpose

Targeted sequence capture coupled to high-throughput sequencing has become a powerful method for the study of genome-wide sequence variation in non-model genomes. Following the recent availability of a genome sequence assembly for the Pink Ipê tree (Handroanthus impetiginosus) that appears in GigaScience Jounal (2018), we reported the development of a set of 24,751 capture probes for single nucleotide polymorphisms (SNPs) characterization and genotyping across 18,216 distinct loci, sampling more than 10 Mbp of the species genome. This system identifies nearly 200,000 SNPs located inside or in close proximity to almost 14,000 annotated protein-coding genes, generating quality genotypic data in populations spanning wide geographic distances across the species native range.

This is the project containing all scripts written and used by the "Design and evaluation of a sequence capture system for genome-wide SNP genotyping of a keystone Neotropical hardwood tree genome" paper published in DNA Research Journal (2018). The pipeline uses freely available software, standard tools, and takes fastq data and a genome assembly sequence as primary inputs. All data are available from NCBI's publicly repositories. 

Briefly, the pipeline guides the user through the following analysis:

## 1. Fastq adaptor- and quality-trimming (automated)
## 2. Short-read alignment (automated)
## 3. Variant calling and genotyping (performed manually)
## 4. Variant filtration (performed manually)
## 5. Variant annotation (performed manually)

The pipeline relies on the use of a distributed memory compute cluster to enable the analyst to run large scale project with  large number of samples.

Analysis 1 & 2 are perfomed in an automated way with a modified version of the scripts provided by the International Cassava Genetic Map Consortium (ICGMC) paper published in G3 Journal (2014). Scripts were originally written for processing Illumina paired-end data or Illumina single-read data and use BWA to align reads against the input reference genome sequence.

Analyses 3 - 5 are perfomed manually and the analyst should consult the Variant Calling and Genotyping section provided herein for step-by-step analysis instructions. Tips on assessing data quality and choosing thresholds are provided in the supplementary file S1 of the manuscript.

Additional resources used by the pipeline are available to the analyst under the directory share in this project. Basically, it includes reference information about reliable SNPs for quality score recalibration using GATK VariantRecalibrator tool and also a reference database of SNP annotations generated using the SNPEff program.Detailed description on how these resources were generated is provided in the supplementary file S1 of the manuscript.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

What things you need to install the software and how to install them

```
Give examples
```

### Installing

A step by step series of examples that tell you have to get a development env running

Say what the step will be

```
Give the example
```

And repeat

```
until finished
```

End with an example of getting some data out of the system or using it for a little demo

## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone who's code was used
* Inspiration
* etc
