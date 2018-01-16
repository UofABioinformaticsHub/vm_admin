#!/usr/bin/Rscript

source("https://bioconductor.org/biocLite.R")
pkgs <- c("reshape2", "ggrepel", "readxl", "AnnotationHub", "biomaRt", "Biostrings", "BSgenome",
          "DESeq2", "GenomicRanges", "GenomicFeatures", "Rsubread", "Rsamtools", "rtracklayer",
          "Gviz", "ggbio", "Biobase", "edgeR", "limma", "Glimma", "xtable", "pander", "knitr",
          "rmarkdown", "lme4", "multcomp", "scales", "stringr", "corrplot", "pheatmap", "devtools", "tidyverse",
          "BiocGenerics", "BiocStyle", "checkmate", "ggdendro", "lubridate", "magrittr",
          "plotly", "shiny", "ShortRead", "viridis", "viridisLite", "zoo", "shinyFiles",
         "UofABioinformaticsHub/ngsReports")
biocLite(pkgs)
biocValid(fix = TRUE)
