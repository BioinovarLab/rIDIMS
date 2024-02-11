
# rIDIMS

<!-- badges: start -->
<!-- badges: end -->

Welcome to rIDIMS, an easy-to-use package designed to simplify processing your direct mass spectrometry data. This tutorial aims to help you effectively use rIDIMS and simplify parameter selection for your analysis.


![image](https://github.com/BioinovarLab/rIDIMS/assets/47224782/0768cc0d-db0c-417d-a632-9071e85e0b0d)


## Installation

Option 1) Download the package at:
https://github.com/BioinovarLab/rIDIMS/releases/download/v1.7.8/rIDIMS_1.7.8.zip

Option 2) Installation from Github
``` r
devtools::install_github("BioinovarLab/rIDIMS")
```



## Screenshot

<img src="https://github.com/BioinovarLab/rIDIMS/assets/47224782/7f742c80-8866-463e-9b61-fba06982002b" width="600">


## Starting the application

``` r
library(rIDIMS)
start_rIDIMS()
```

## Tutorial


1- Input files 
Make sure the files are in open data format (.mzML or .mzXML ). Then, copy the directory path and paste it into the “Spectra files directory” field. A list file containing sample information is required. If you are processing your data for the first time, click the “Make information file” button. A spreadsheet “sample.info” listing all the files in the directory is generated, and it will open automatically, or you can access it in your files directory. This file consists of four columns containing file directory location, sample name, replicates, and class information. To ensure comprehensive data processing, make sure to fill in the “replicate” and “class” columns for each sample in your dataset.

<img src="https://github.com/BioinovarLab/rIDIMS/assets/47224782/a6c9b1de-6c88-486d-8180-8f875e0374a0" width="400">


See the example below:

<img src="https://github.com/BioinovarLab/rIDIMS/assets/47224782/fc978ce4-ee18-4b14-9463-9d3c259ed308" width="400">

 
●	Note that if your dataset contains technical replicates, you can use a code, sample name, number, or letter to identify them. However, it is necessary to maintain consistency by using the same identifier for replicates of the same sample, whereas different samples require unique identifiers.
●	Blank/background and QC samples must be identified in the class column.
If you have already created an "information file", then proceed by clicking the "Open information file" button to load the data. This will generate a pie chart showing the relative proportions of each sample class in the dataset. That gives you an overview of your dataset and allows you to identify potential mistakes in the previous step.

<img src="[https://github.com/BioinovarLab/rIDIMS/assets/47224782/fc978ce4-ee18-4b14-9463-9d3c259ed308](https://github.com/BioinovarLab/rIDIMS/assets/47224782/6158082f-3376-430b-8dfd-4ee30158763f)" width="400">



## Data Processing

### Parameters

**MS Resolution** – Select the resolution mass spectrometer (low or high) that you used to acquire the data.

**BinSize (Dalton)** –This parameter defines the bin size, expressed in Dalton, to align the peaks in the samples. The maximum interval along the m/z axis to which two or more peaks must belong in order for them to be considered the same peak. It should be stimulated based on the mass accuracy achieved in the experiment.

**SNR Threshold**: Set a minimal signal-to-noise ratio (S/N) for peaks to be detected.

**AggregationFun of chromatogram** – Function used to aggregate intensity values for the same retention time across the mz range. The values could be aggregated by sum (Total Ion Chromatogram – TIC) or max (Base Peak Chromatogram – BPC).

**Filter chromatogram by x% of maximum value** – Use for selecting high-quality scans, removing low-intensity scans or scans with zero value. It will filter the chromatogram scans using the percentage specified in "Filter chromatogram by x% of maximum value," selecting only scans with intensities greater than the value calculated from the maximum intensity.

**Make 3 replicates/samples** – Select if you want to generate in-silico replicates only. This option will separate scans of each file into 3 groups (1, 2, and 3), where each scan group represents a replica.

**ppm for grouping of mass peaks** – The maximum tolerance of m/z to group the mass peaks.

**Filter spectrum intensity by x% of maximum value** – Filter ions based on their relative abundance.

### Data Filtering

**Filter replicate** - Select if there are technical replicates in your dataset. This procedure consists of grouping the samples according to their respective replicates, then removing ions present in less than (user-defined threshold) of technical replicates per sample. The process only considers the replicates specified in the sample.info file, excluding any in-silico replicas. 

**Replicate threshold (%)** –The percentage to filter the ions in the replicates. By default, this threshold is set to 66%, which means that ions found in less than 66% of the technical replicates (equivalent to 2 out of 3) will be excluded from the data matrix.
Note: Once this process is completed, a new data matrix named “Data_metaboanalyst_replicates_filtered_66.csv" is generated in your directory.

**Subtract from the data matrix (blank/background ion class)** - Subtraction of the blank/background ions in the dataset. The procedure consists of removing ions with an average intensity ratio between the sample and the blank below the user-defined threshold. 
Minimum fold change – Minimum sample: blank peak intensity ratio to subtract ions from the sample. The default is 3.
Note: Once this process is completed, a new data matrix named “Data_substrated_3_MFC_metaboanalyst” is generated in your directory.

### Samples filter 
Select the “Filter all samples” option to retain peaks within a defined minimum percentage of all samples in your dataset. The default is 80%. Be cautious with the threshold if you have more than two groups in your dataset. Revise your experimental design to choose the appropriate threshold.
**Note:** Once this process is completed, a new data matrix named “Data_metaboanalyst_samples_filtered_80” is generated in your directory.

Select the **“Filter by class”** to filter ions by removing those that occur in less than (user-defined threshold) of the samples from each class. The default is 50% for a more flexible filter. You must choose a threshold based on the size of your samples within each class. 
**Note:** Once this process is completed, a new data matrix named “Data_metaboanalyst_class_filtered_50” is generated in your directory.

To not filter ions by samples, select the “Do not filter samples” option.

**Number of cores** – Number of cores from the processor (CPU) of the computer to be used during the rIDIMS process. The default is 6 for better performance.

**Make Heatmaps** – Build the data heatmap before and after the processing step. However, this option is set to FALSE by default as it uses memory intensively.

____________________________________________________________________________
Click on **“Start process!”** to start processing the files. During this, a log file is created in the file directory, where you can track all the processing steps. 
Once the process is finished, you can view the processing results within the Report file.

