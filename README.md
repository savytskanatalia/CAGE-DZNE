# CAGE-DZNE
CAGE-related toolset



This toolset allows processing CAGE-seq raw data, according to the pipeline developed at the DZNE Tuebingen AG Heutink/Bioinformatics by Dr.Margherita Francescatto (2015, unpublished).

The Dockerfile allows installing R-base, Python3, TagDust 2.33 (reads extractor), skewer (adaptor trimmer), STAR 2.6.0a (RNAseq-aligner) in a container.




*To build image:*

docker build - < Dockerfile -t $TAGOFYOURCHOICE

*To mount container:*

docker run -it -v /directory/of/your/choice:/data $TAGOFYOURCHOICE
