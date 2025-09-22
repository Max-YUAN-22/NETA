# NETA Shiny Application
# Neuroendocrine Tumor Atlas - Bulk RNA-seq Database

# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(ComplexHeatmap)
library(circlize)
library(RColorBrewer)
library(limma)
library(edgeR)
library(GSEABase)
library(fgsea)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "NETA: Neuroendocrine Tumor Atlas"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("数据概览", tabName = "overview", icon = icon("dashboard")),
      menuItem("基因表达分析", tabName = "expression", icon = icon("chart-line")),
      menuItem("差异表达分析", tabName = "de_analysis", icon = icon("chart-bar")),
      menuItem("生存分析", tabName = "survival", icon = icon("heartbeat")),
      menuItem("通路分析", tabName = "pathway", icon = icon("project-diagram")),
      menuItem("数据下载", tabName = "download", icon = icon("download"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f8f9fa;
        }
        .box {
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .nav-tabs-custom > .nav-tabs > li.active > a {
          background-color: #7c3aed;
          color: white;
        }
      "))
    ),
    
    tabItems(
      # 数据概览页面
      tabItem(tabName = "overview",
        fluidRow(
          box(
            title = "数据库统计", status = "primary", solidHeader = TRUE,
            width = 12,
            fluidRow(
              valueBoxOutput("total_samples"),
              valueBoxOutput("total_genes"),
              valueBoxOutput("tumor_types")
            )
          )
        ),
        fluidRow(
          box(
            title = "样本分布", status = "info", solidHeader = TRUE,
            width = 6,
            plotlyOutput("sample_distribution")
          ),
          box(
            title = "基因表达分布", status = "success", solidHeader = TRUE,
            width = 6,
            plotlyOutput("expression_distribution")
          )
        ),
        fluidRow(
          box(
            title = "样本信息表", status = "warning", solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("sample_table")
          )
        )
      ),
      
      # 基因表达分析页面
      tabItem(tabName = "expression",
        fluidRow(
          box(
            title = "基因搜索", status = "primary", solidHeader = TRUE,
            width = 4,
            textInput("gene_search", "输入基因名称:", placeholder = "例如: SYP, CHGA, INS"),
            selectInput("tumor_type", "选择肿瘤类型:", 
                       choices = c("All", "Pancreatic NET", "Lung NET", "GEP-NET", "Other")),
            actionButton("search_gene", "搜索", class = "btn-primary")
          ),
          box(
            title = "基因表达热图", status = "info", solidHeader = TRUE,
            width = 8,
            plotlyOutput("gene_heatmap", height = "500px")
          )
        ),
        fluidRow(
          box(
            title = "基因表达箱线图", status = "success", solidHeader = TRUE,
            width = 12,
            plotlyOutput("gene_boxplot", height = "400px")
          )
        )
      ),
      
      # 差异表达分析页面
      tabItem(tabName = "de_analysis",
        fluidRow(
          box(
            title = "分析参数", status = "primary", solidHeader = TRUE,
            width = 4,
            selectInput("group1", "对照组:", choices = NULL),
            selectInput("group2", "实验组:", choices = NULL),
            numericInput("fc_threshold", "Fold Change阈值:", value = 1.5, min = 1, max = 5, step = 0.1),
            numericInput("pval_threshold", "P值阈值:", value = 0.05, min = 0.001, max = 0.1, step = 0.001),
            actionButton("run_de_analysis", "运行分析", class = "btn-primary")
          ),
          box(
            title = "火山图", status = "info", solidHeader = TRUE,
            width = 8,
            plotlyOutput("volcano_plot", height = "500px")
          )
        ),
        fluidRow(
          box(
            title = "差异表达基因表", status = "success", solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("de_table")
          )
        )
      ),
      
      # 生存分析页面
      tabItem(tabName = "survival",
        fluidRow(
          box(
            title = "生存分析参数", status = "primary", solidHeader = TRUE,
            width = 4,
            selectInput("survival_gene", "选择基因:", choices = NULL),
            selectInput("survival_endpoint", "终点事件:", 
                       choices = c("Overall Survival", "Progression-free Survival")),
            numericInput("survival_cutoff", "表达量分位数:", value = 0.5, min = 0.1, max = 0.9, step = 0.1),
            actionButton("run_survival", "运行生存分析", class = "btn-primary")
          ),
          box(
            title = "Kaplan-Meier生存曲线", status = "info", solidHeader = TRUE,
            width = 8,
            plotlyOutput("survival_plot", height = "500px")
          )
        ),
        fluidRow(
          box(
            title = "Cox回归分析结果", status = "success", solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("cox_table")
          )
        )
      ),
      
      # 通路分析页面
      tabItem(tabName = "pathway",
        fluidRow(
          box(
            title = "通路分析参数", status = "primary", solidHeader = TRUE,
            width = 4,
            selectInput("pathway_database", "通路数据库:", 
                       choices = c("KEGG", "GO", "Reactome", "MSigDB")),
            selectInput("pathway_category", "通路类别:", 
                       choices = c("All", "Metabolism", "Signaling", "Immune", "Cell Cycle")),
            actionButton("run_pathway", "运行通路分析", class = "btn-primary")
          ),
          box(
            title = "通路富集图", status = "info", solidHeader = TRUE,
            width = 8,
            plotlyOutput("pathway_plot", height = "500px")
          )
        ),
        fluidRow(
          box(
            title = "通路富集结果表", status = "success", solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("pathway_table")
          )
        )
      ),
      
      # 数据下载页面
      tabItem(tabName = "download",
        fluidRow(
          box(
            title = "数据下载", status = "primary", solidHeader = TRUE,
            width = 12,
            h4("可下载的数据文件:"),
            br(),
            downloadButton("download_expression", "下载表达矩阵", class = "btn-success"),
            downloadButton("download_metadata", "下载样本信息", class = "btn-info"),
            downloadButton("download_de_results", "下载差异表达结果", class = "btn-warning"),
            br(), br(),
            h4("使用说明:"),
            p("1. 表达矩阵文件包含所有样本的基因表达数据"),
            p("2. 样本信息文件包含临床和病理信息"),
            p("3. 差异表达结果文件包含最新的分析结果"),
            br(),
            h4("数据格式:"),
            p("所有文件均为CSV格式，可用Excel或R/Python读取")
          )
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # 模拟数据加载
  load_sample_data <- reactive({
    # 这里应该加载真实的神经内分泌肿瘤数据
    # 示例数据
    set.seed(123)
    n_samples <- 200
    n_genes <- 20000
    
    # 生成模拟表达数据
    expression_data <- matrix(rnorm(n_samples * n_genes, mean = 8, sd = 2), 
                             nrow = n_genes, ncol = n_samples)
    rownames(expression_data) <- paste0("GENE_", 1:n_genes)
    colnames(expression_data) <- paste0("SAMPLE_", 1:n_samples)
    
    # 生成样本信息
    sample_info <- data.frame(
      Sample_ID = colnames(expression_data),
      Tumor_Type = sample(c("Pancreatic NET", "Lung NET", "GEP-NET", "Other"), 
                          n_samples, replace = TRUE),
      Grade = sample(c("G1", "G2", "G3"), n_samples, replace = TRUE),
      Stage = sample(c("I", "II", "III", "IV"), n_samples, replace = TRUE),
      OS_Status = sample(c("Alive", "Dead"), n_samples, replace = TRUE),
      OS_Time = runif(n_samples, 10, 2000),
      stringsAsFactors = FALSE
    )
    
    list(expression = expression_data, metadata = sample_info)
  })
  
  # 数据概览页面
  output$total_samples <- renderValueBox({
    data <- load_sample_data()
    valueBox(
      value = ncol(data$expression),
      subtitle = "总样本数",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$total_genes <- renderValueBox({
    data <- load_sample_data()
    valueBox(
      value = nrow(data$expression),
      subtitle = "总基因数",
      icon = icon("dna"),
      color = "green"
    )
  })
  
  output$tumor_types <- renderValueBox({
    data <- load_sample_data()
    valueBox(
      value = length(unique(data$metadata$Tumor_Type)),
      subtitle = "肿瘤类型",
      icon = icon("hospital"),
      color = "yellow"
    )
  })
  
  output$sample_distribution <- renderPlotly({
    data <- load_sample_data()
    plot_ly(data$metadata, x = ~Tumor_Type, type = "histogram") %>%
      layout(title = "样本类型分布",
             xaxis = list(title = "肿瘤类型"),
             yaxis = list(title = "样本数量"))
  })
  
  output$expression_distribution <- renderPlotly({
    data <- load_sample_data()
    expression_values <- as.vector(data$expression)
    plot_ly(x = expression_values, type = "histogram") %>%
      layout(title = "基因表达分布",
             xaxis = list(title = "表达值"),
             yaxis = list(title = "频数"))
  })
  
  output$sample_table <- DT::renderDataTable({
    data <- load_sample_data()
    DT::datatable(data$metadata, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  filter = "top")
  })
  
  # 基因表达分析页面
  observeEvent(input$search_gene, {
    # 这里实现基因搜索逻辑
    # 更新热图和箱线图
  })
  
  output$gene_heatmap <- renderPlotly({
    # 生成示例热图
    plot_ly(z = matrix(rnorm(100), 10, 10), type = "heatmap") %>%
      layout(title = "基因表达热图")
  })
  
  output$gene_boxplot <- renderPlotly({
    # 生成示例箱线图
    plot_ly(y = rnorm(100), type = "box") %>%
      layout(title = "基因表达箱线图",
             yaxis = list(title = "表达值"))
  })
  
  # 差异表达分析页面
  output$volcano_plot <- renderPlotly({
    # 生成示例火山图
    plot_ly(x = rnorm(1000), y = -log10(runif(1000)), 
            type = "scatter", mode = "markers") %>%
      layout(title = "火山图",
             xaxis = list(title = "Log2 Fold Change"),
             yaxis = list(title = "-Log10 P-value"))
  })
  
  output$de_table <- DT::renderDataTable({
    # 生成示例差异表达结果表
    de_results <- data.frame(
      Gene = paste0("GENE_", 1:100),
      LogFC = rnorm(100),
      PValue = runif(100),
      FDR = runif(100),
      stringsAsFactors = FALSE
    )
    DT::datatable(de_results, options = list(pageLength = 10))
  })
  
  # 生存分析页面
  output$survival_plot <- renderPlotly({
    # 生成示例生存曲线
    plot_ly(x = 1:100, y = exp(-0.01 * 1:100), type = "scatter", mode = "lines") %>%
      layout(title = "Kaplan-Meier生存曲线",
             xaxis = list(title = "时间 (天)"),
             yaxis = list(title = "生存概率"))
  })
  
  output$cox_table <- DT::renderDataTable({
    # 生成示例Cox回归结果
    cox_results <- data.frame(
      Gene = paste0("GENE_", 1:50),
      HR = exp(rnorm(50)),
      CI_Lower = exp(rnorm(50) - 0.5),
      CI_Upper = exp(rnorm(50) + 0.5),
      PValue = runif(50),
      stringsAsFactors = FALSE
    )
    DT::datatable(cox_results, options = list(pageLength = 10))
  })
  
  # 通路分析页面
  output$pathway_plot <- renderPlotly({
    # 生成示例通路富集图
    plot_ly(x = 1:20, y = -log10(runif(20)), 
            type = "bar", text = paste0("Pathway_", 1:20)) %>%
      layout(title = "通路富集分析",
             xaxis = list(title = "通路"),
             yaxis = list(title = "-Log10 P-value"))
  })
  
  output$pathway_table <- DT::renderDataTable({
    # 生成示例通路富集结果
    pathway_results <- data.frame(
      Pathway = paste0("Pathway_", 1:50),
      Description = paste0("Description for pathway ", 1:50),
      Size = sample(10:200, 50),
      PValue = runif(50),
      FDR = runif(50),
      stringsAsFactors = FALSE
    )
    DT::datatable(pathway_results, options = list(pageLength = 10))
  })
  
  # 数据下载页面
  output$download_expression <- downloadHandler(
    filename = function() {
      paste("NETA_expression_matrix_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      data <- load_sample_data()
      write.csv(data$expression, file, row.names = TRUE)
    }
  )
  
  output$download_metadata <- downloadHandler(
    filename = function() {
      paste("NETA_sample_metadata_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      data <- load_sample_data()
      write.csv(data$metadata, file, row.names = FALSE)
    }
  )
  
  output$download_de_results <- downloadHandler(
    filename = function() {
      paste("NETA_DE_results_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      # 生成示例差异表达结果
      de_results <- data.frame(
        Gene = paste0("GENE_", 1:1000),
        LogFC = rnorm(1000),
        PValue = runif(1000),
        FDR = runif(1000),
        stringsAsFactors = FALSE
      )
      write.csv(de_results, file, row.names = FALSE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
