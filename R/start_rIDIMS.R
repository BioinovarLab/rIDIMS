#' start_rIDIMS
#' @name start_rIDIMS
#' @return null
#' @export
#' @import shiny
#' @import shinyjs
#' @importFrom plotly plotlyOutput renderPlotly plot_ly add_pie layout
#' @import ggplot2
#' @importFrom dplyr select filter mutate group_by summarise across select_if %>%
#' @importFrom xcms MatchedFilterParam snthresh findChromPeaks chromatogram filterAcquisitionNum
#' @importFrom Spectra Spectra MsBackendDataFrame bin peaksData mz intensity
#' @import MassSpecWavelet
#' @import writexl
#' @import anticlust
#' @import tinytex
#' @import reshape2
#' @importFrom readxl read_excel
#' @import foreach
#' @importFrom doParallel registerDoParallel
#' @importFrom parallel makeCluster stopCluster
#' @importFrom utils packageVersion
#' @importFrom tidyr gather
#' @importFrom stats aggregate
#'

#usethis::use_package("signal")
#devtools::check()
#devtools::document()
#devtools::document(roclets = c('rd', 'collate', 'namespace'))
#https://www.paulamoraga.com/blog/2022/04/12/2022-04-12-rpackages/


start_rIDIMS <- function() {
debug_app=TRUE
QC_app=FALSE
n.cores <- parallel::detectCores() -2

check.all.numeric <- function(vector){
  stringr::str_detect(vector,"^[:digit:]+$")
}

ui <-
  navbarPage("rIDIMS", collapsible = TRUE,
             tabPanel("Files process",
                      fluidPage(
                        useShinyjs(),
                                   sidebarLayout(
                                     sidebarPanel("Parameters",br(),
                                                  selectInput("input.msresolution", "MS Resolution",selectize = F,
                                                              c("Low Resolution" = "low.res",
                                                                "High Resolution" = "high.res")),
                                                  textInput("input.binSize", "binSize (Dalton)","1"),
                                                  textInput("input.snthresh", "SNR threshold","1"),
                                                  #hidden(textInput("input.scales", "Scales (MSWParam)","1,4")),
                                                  #hidden(textInput("input.peakThr", "Peak Thr (MSWParam)","1000")),
                                                  #hidden(textInput("input.ampTh", "Amp. Th (MSWParam)","0.001")),
                                                  radioButtons(inputId = "input.aggregationFun",
                                                               label = "AggregationFun of chromatogram",
                                                               choices = c("sum (TIC)" = "sum", "max (BPC)" = "max"),
                                                               selected = "sum",
                                                               inline = TRUE),
                                                  textInput("input.chr.limit", "Filter chromatogram by x% of maximum value","10"),
                                                  checkboxInput("input.replicates", "Make 3 replicates / sample", value=TRUE),
                                                  textInput("input.ppm", "ppm for grouping of mass peaks (low.res)","200"),
                                                  textInput("input.Tresh.RA", "Filter spectrum intensity by x% of maximum value","0.1"),
                                                  checkboxInput("input.replicate.filter", "Filter replicate", value=TRUE),
                                                  textInput("input.value.replicate.filter", "Filter replicate threshold (%)","60"),
                                                  textInput("input.subtract.group", "Subtract from the data matrix (blank/background ions class)","blank"),
                                                  textInput("input.min.fold", "Minimum fold change","3"),
                                                  #checkboxInput("input.class.mean", "Class filter (with-in)", value=TRUE),

                                                  selectInput("input.sample.filter", "Samples filter",selectize = F,
                                                              c("Filter all samples" = "sample.filter.all.samples",
                                                                "Filter by class" = "sample.filter.by.class",
                                                                "Do not filter samples" = "no.sample.filter")),
                                                  textInput("input.class.mean.filter", "Filter threshold (%)","80"),


                                                  textInput("input.n.cores", "Number of cores",n.cores),
                                                  checkboxInput("input.make.heatmaps", "Make Heatmaps", value=FALSE)
                                     ),
                                     mainPanel(
                                       fluidRow(
                                         wellPanel(
                                           h4("Input files")     ,
                                           h5("If you do not have a sample information file, enter the folder directory that contains all the spectra files
                                              and click on the \"Make information file\" option. A spreadsheet will be generated listing the files for
                                              you to fill in the required information. If this procedure has already been completed, select the \"Open information file\" option."),
                                           textInput("files.path", "Spectra files directory","enter directory path"),
                                           actionButton("create.sample.filo.btn", "Make information file", class = "btn-success",
                                                        style = "width:200px"),
                                           actionButton("selec.sample.filo.btn", "Open information file", class = "btn-success",
                                                        style = "width:200px"),
                                           br()
                                         ),
                                         wellPanel(
                                           h4("Sample data")     ,
                                           verbatimTextOutput("sample.info.txt1", placeholder = TRUE),
                                           plotlyOutput("sample.info.plot1"),
                                           br()
                                         ),
                                         wellPanel(
                                           actionButton("init.btn", "Start process!", class = "btn-success")
                                         )
                                       ),
                                       br(),
                                     )
                                   )))

             )

clean.path <- function(path) {
  new <- gsub("\\\\", "/", path)
  if (substr(new,nchar(new),nchar(new)) != "/"){
    new <- paste0(new,"/")
  }
  return(new)
}

server <- function(input, output,session) {

  session.vars <- reactiveValues(data.folder = NULL,
                                 output.folder = NULL,
                                 samples.info=NULL)

  #input.class.mean
  observeEvent(input$input.sample.filter, {
    if((input$input.sample.filter=="no.sample.filter")) {
      shinyjs::hide(id = "input.class.mean.filter");
    }
    if((input$input.sample.filter!="no.sample.filter")) {
      shinyjs::show(id = "input.class.mean.filter");
    }

  }, ignoreInit = TRUE, ignoreNULL = FALSE) #end

  #input.replicate.filter
  observeEvent(input$input.replicate.filter, {

    if((input$input.replicate.filter=="FALSE")) {
      shinyjs::hide(id = "input.value.replicate.filter");
    }
    if((input$input.replicate.filter=="TRUE")) {
      shinyjs::show(id = "input.value.replicate.filter");
    }


  }, ignoreInit = TRUE, ignoreNULL = FALSE) #end


  #input.msresolution
  observeEvent(input$input.msresolution, {
    if((input$input.msresolution=="low.res")) {
      #shinyjs::hide(id = "input.scales");
      #shinyjs::hide(id = "input.peakThr");
      #shinyjs::hide(id = "input.ampTh");
      updateTextInput(session, "input.ppm",  label = "ppm for grouping of mass peaks (low.res)", value = "200")
      updateTextInput(session, "input.binSize",  label = "binSize (Dalton)", value = "1")
      #shinyjs::show(id = "input.binSize");
      #shinyjs::show(id = "input.snthresh");

    }
    if((input$input.msresolution=="high.res")) {
      #shinyjs::show(id = "input.scales");
      #shinyjs::show(id = "input.peakThr");
      #shinyjs::show(id = "input.ampTh");
      updateTextInput(session, "input.ppm",  label = "ppm for grouping of mass peaks (high.res)", value = "10")
      updateTextInput(session, "input.binSize",  label = "binSize (Dalton)", value = "0.00001")
      #shinyjs::hide(id = "input.binSize");
      #shinyjs::hide(id = "input.snthresh");
    }

  }, ignoreInit = TRUE, ignoreNULL = FALSE) #end input.msresolution

  #create.sample.filo.btn
  observeEvent(input$create.sample.filo.btn, {
    req(input$files.path)
    data.folder <- clean.path(input$files.path)

    if (file.exists(paste0(data.folder,"/samples.info.xlsx"))){
      showModal(modalDialog(title="Important message",
                            "File already exists!",
                            easyClose = TRUE));return(NULL);
    }
    showModal(modalDialog("Creating the file. Please wait.", footer=NULL))

    if (dir.exists(paste0(data.folder,"Output_Spectra"))){
      unlink(paste0(data.folder,"Output_Spectra"),recursive=TRUE)
    }

    data.file.names <- dir(data.folder, full.names = TRUE, pattern = ".CDF|.cdf|.mzXML|.mzML|.mzml|.MZML",recursive = T)

    #shQuote(normalizePath(paste0(data.folder

    if (length(data.file.names) == 0){
      showModal(modalDialog(title="Important message","Not valid folder. Can't find MS files.",
                            easyClose = TRUE));return(NULL);
    }



    #return(NULL)
    samples.info <- data.frame(file.dir = data.file.names,
                               sample = (basename(data.file.names)),
                               replicate=0,
                               class=0)
    rownames(samples.info) <- (samples.info$sample)

    if(length(unique(samples.info$sample)) != nrow(samples.info)){
      message("Error. Must have unique file names.")
      stop()
    }

    save(data.file.names,samples.info, data.folder, file = paste0(data.folder,"data.file.Rda"))

    writexl::write_xlsx(samples.info,paste0(data.folder,"/samples.info.xlsx"))



    system2("open", shQuote(normalizePath(paste0(data.folder,"samples.info.xlsx"))))

    # if(.Platform$OS.type == "unix") {
    # } else {
    #   base::shell.exec(normalizePath(paste0(data.folder,"samples.info.xlsx")))
    # }


    session.vars$data.folder <- data.folder
    removeModal()
    # withProgress(message = "Loading file...", value = 0, {
    #   for (i in 1:10) {
    #     Sys.sleep(0.05)
    #     incProgress(1/10)
    #   }
    # })

  }) #end create.sample.filo.btn

  #selec.sample.filo.btn
  observeEvent(input$selec.sample.filo.btn, {
    req(input$files.path)
    data.folder<-clean.path(input$files.path)

    if (!file.exists(paste0(data.folder,"samples.info.xlsx"))){
      showModal(modalDialog(title="Important message",
                            "File samples.info.xlsx not found!",
                            easyClose = TRUE));return(NULL);
    }
    output$sample.info.txt1 <- renderText({ paste("Loading...", nrow(samples.info)) })
    showModal(modalDialog("Loading the file. Please wait.", footer=NULL))
    samples.info <- readxl::read_excel(paste0(data.folder,"/samples.info.xlsx"), col_names = T)

    fig <- plotly::plot_ly()
    #fig <- fig %>% add_pie(samples.info, labels = samples.info$type, values = 1, type = 'pie',
    #                       textposition = 'inside',
    #                       textinfo = 'label+percent',
    #                       domain = list(row = 0, column = 0))
    fig <- fig %>% add_pie(samples.info, labels = samples.info$class, values = 1, type = 'pie',
                           textposition = 'inside',
                           textinfo = 'label+percent',
                           domain = list(row = 0, column = 0))
    fig <- fig %>% layout(title = "Samples distribution per class", showlegend = F,
                          grid=list(rows=1, columns=2),
                          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))

    output$sample.info.plot1<- renderPlotly({ print(fig) })
    output$sample.info.txt1 <- renderText({ paste("We have loaded", nrow(samples.info), "files.") })


    rownames(samples.info) <- samples.info$sample
    samples.info$replicate <- as.character(samples.info$replicate)
    output.folder <- paste0(data.folder,"Output_Spectra/")

    session.vars$data.folder <- data.folder
    session.vars$output.folder <- output.folder
    session.vars$samples.info <- samples.info
    session.vars$debug_app <- debug_app
    session.vars$QC_app <- QC_app
    removeModal()

    #@loadSupport("teste.funcoes.R")
    #source("teste.funcoes.R")

  }) #end selec.sample.filo.btn

  #init.btn
  observeEvent(input$init.btn, {
    req(session.vars$data.folder)
    req(session.vars$output.folder)
    req(input$input.binSize)
    req(input$input.snthresh)
    req(input$input.aggregationFun)
    req(input$input.ppm)
    #req(input$input.Tresh.RA)
    req(input$input.chr.limit)
    #req(input$input.scales)
    req(session.vars$samples.info)

    data.folder<-(session.vars$data.folder)
    output.folder<-(session.vars$output.folder)
    input.binSize<-as.numeric(input$input.binSize)
    input.snthresh<-as.numeric(input$input.snthresh)
    input.aggregationFun<-(input$input.aggregationFun)
    input.replicates<-as.character(input$input.replicates)
    input.ppm<-as.numeric(input$input.ppm)
    input.Tresh.RA<-as.numeric(input$input.Tresh.RA)
    input.subtract.group<-as.character(input$input.subtract.group)
    input.min.fold <- as.numeric(input$input.min.fold)
    input.chr.limit<-as.numeric(input$input.chr.limit)
    samples.info <- session.vars$samples.info
    input.msresolution<-as.character(input$input.msresolution)
    input.class.mean <- as.character(input$input.class.mean)
    input.sample.filter <- as.character(input$input.sample.filter)

    input.class.mean.filter <- as.numeric(input$input.class.mean.filter)
    input.replicate.filter <- as.character(input$input.replicate.filter)
    input.value.replicate.filter <- as.numeric(input$input.value.replicate.filter)
    input.make.heatmaps <- as.character(input$input.make.heatmaps)
    report.serial <- format(Sys.time(), "%Y_%m_%d_%H_%M_%S")



    if (debug_app==TRUE){
      save(    data.folder,
               output.folder,
               input.binSize,
               input.snthresh,
               input.aggregationFun,
               input.replicates,
               input.ppm,
               input.Tresh.RA,
               input.subtract.group,
               input.min.fold,
               input.chr.limit,
               samples.info ,
               input.msresolution,
               input.class.mean,
               input.sample.filter,
               input.class.mean.filter,
               input.replicate.filter,
               input.value.replicate.filter,
               input.make.heatmaps,
               report.serial,
               file=paste0(data.folder,"variables_step_1.Rda"))
    }


    #check input.subtract.group
     if (input.subtract.group != ""){
        if (!input.subtract.group %in% samples.info$class){
          showModal(modalDialog(title="Error",
                                "Subtract group: Name not found.",
                                easyClose = TRUE));return(NULL);
         }
      }

    #check replicates names
    if (input.subtract.group != ""){

      grouped_data <- stats::aggregate(class ~ replicate, samples.info, FUN = function(x) length(unique(x)))
      multi_class_replicates <- grouped_data$replicate[grouped_data$class > 1]

      if (length(multi_class_replicates) > 0) {

        showModal(modalDialog(title="Error",
                              paste("Replicate codes must be unique for each class. Duplicates:",
                                    paste(multi_class_replicates, collapse = ", ")),
                              easyClose = TRUE));return(NULL);

      }



    }


    if (is.na(input.binSize)== TRUE){
      showModal(modalDialog(title="Error",
                            "Check binSize (low resolution) OR ppm (high resolution) values. It must be numeric.",
                            easyClose = TRUE));return(NULL);
    }


    showModal(modalDialog(paste0("Processing the files. Wait ...",
                                 "Open the log file in the data folder to track updates."), footer=NULL,size = "l"))

    session.parameters <- data.frame(values = t(data.frame(
      MS = input.msresolution,
      BinSize.PPM = input.binSize,
      Snthresh = input.snthresh,
      aggregationFun = input.aggregationFun,
      replicates = input.replicates,
      PPM = input.ppm,
      Tresh.RA = input.Tresh.RA,
      Subtract = input.subtract.group,
      MinFold = input.min.fold,
      Chr.limit = input.chr.limit,
      ClassFilter = input.sample.filter,
      ClassFilterValue = input.class.mean.filter,
      ReplicateFilter = input.replicate.filter,
      ReplicateFilterValue = input.value.replicate.filter,
      MakeHeatmaps = input.make.heatmaps,
      ReportSerial = report.serial,
      debug_app = debug_app,
      QC_app = QC_app,
      PackageVersion = packageVersion("rIDIMS"),
      Data.folder=data.folder,
      Output.folder=output.folder)))

    if (debug_app==TRUE){
      save(session.parameters,file=paste0(data.folder,"session.par.Rda"))
    }


    file.error <- c("")
    for (i in 1:nrow(samples.info)){
      if (!file.exists(samples.info$file.dir[i])){
        file.error <- paste0(file.error, basename(samples.info$file.dir[i]) , ", ")
      }
    }
    if (file.error!=""){
      showModal(modalDialog(title="Error",
                            paste0("Not found: ", file.error ),
                            easyClose = TRUE));return(NULL);
    }

    dir.create(output.folder)

    report.name <- paste0("Report_", report.serial  )
    rmarkdown::render(system.file("rmd", "report_template.Rmd", package = "rIDIMS"), output_dir=data.folder,
                        output_file=report.name)
    #print(script.error)
    removeModal()

    system2("open", shQuote(normalizePath(paste0(data.folder, report.name,".html" ))))


    showModal(modalDialog(paste0("The process ended successfully. Check the report at: ",
                                 data.folder, report.name,".html"), footer=NULL, size = "l",
                          easyClose = TRUE))


    ###############################################################
    ###############################################################


  })#end input$init.btn


}#end server

shinyApp(ui, server)


}#end start_rIDIMS()



