
# rIDIMS

<!-- badges: start -->
<!-- badges: end -->

Welcome to rIDIMS, an easy-to-use application/package designed to simplify processing your direct mass spectrometry data.
Spectra obtained by direct-infusion mass spectrometry (DIMS) can be challenging. There may be few samples and/or samples with limited surface area. In these cases, the chronogram presents challenging curves for processing. Many existing algorithms are not prepared to process regions with zeroed scans, for example. 
rIDIMS emerges as the ideal tool for processing DIMS data with an innovation in reproducible and statistically robust scan selection.
See a typical example of a chronogram below.

![TICs_example](https://github.com/user-attachments/assets/4b28a772-f193-4e64-aca8-14f63907f431)

This example is from a single sample. Note that in this single run (injection) there are TICs with *valid* and *invalid scans* (regions with zeroed scans and noise). 
The goal is to extract valid scans from this spectrum in a rational manner. To do this, the rIDIMS algorithm removes regions with zeroed scans and noise, and then selects TICs that present values above an established threshold.



## Installation (Recommended)

rIDIMS should be installed with the `pak` package. `pak` is the best option because it is able to install automatically
all dependencies from various sources such as CRAN, Bioconductor, GitHub, URLs, git repositories.

1) Install `pak` package
``` r
install.packages("pak")
```
2) Install `rIDIMS` package
``` r
pak::pkg_install("url::https://github.com/BioinovarLab/rIDIMS/releases/download/v0.5.00/rIDIMS_0.5.00.tar.gz")
```

## Start the application

``` r
library(rIDIMS)
start_rIDIMS()
```

## Screenshot

<img src="https://github.com/BioinovarLab/rIDIMS/assets/47224782/7f742c80-8866-463e-9b61-fba06982002b" width="600">


## Prerequisites:
* **Windows:** Install the latest version of *[Rtools](http://cran.r-project.org/bin/windows/Rtools)*. It is advised to install in the default location which is C:\Rtools.
* **Linux:** Make sure to have `r-base-dev` installed. *[HowTO](https://cran.r-project.org/bin/linux/debian/)*. 
* **OSX:** Make sure to have `Xcode` developer tools from Apple installed. *[Tutorial](https://mac.r-project.org/tools/)*. 


### [Click here for the extended tutorial.](https://bioinovarlab.github.io/rIDIMS/articles/rIDIMS.html)




