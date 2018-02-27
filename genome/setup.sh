#!/bin/bash

# Check that external tools are accessible:
ZCAT=`which zcat`;
WGET=`which wget`;

if [[ -z "${ZCAT}" || ! -x "${ZCAT}" ]]; then
    error 127 "zcat not in PATH env variable or not executable";

elif [[ -z "${WGET}" || ! -x "${WGET}" ]]; then
    error 127 "wget not in PATH env variable or not executable";

fi

wget ftp://ftp.ncbi.nlm.nih.gov/sra/wgs_aux/NK/XS/NKXS01/NKXS01.1.fsa_nt.gz

wget ftp://ftp.ncbi.nlm.nih.gov/sra/wgs_aux/NK/XS/NKXS01/NKXS01.2.fsa_nt.gz

zcat NKXS01.1.fsa_nt.gz NKXS01.2.fsa_nt.gz | sed -re 's/^>(\S+)\.[0-9]+\s+.*/>\1/' > genome.fasta

rm *.gz
