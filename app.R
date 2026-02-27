# # library(shiny)
# # library(bslib)
# # library(stringr)
# # library(dplyr)
# # library(tidyr)
# # 
# # # 1. LOAD DATA: Definitions and Image List
# # img_dir <- "www/" 
# # all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")
# # 
# # # Load Cleaned Definitions
# # df_raw <- read.csv("classes_definitions.csv", stringsAsFactors = FALSE, check.names = FALSE)
# # 
# # # Standardize critical column names from your CSV
# # # Columns: Level 1, Level 2, Class_name_in_images, Description Ecological - general, Description FCC - general
# # colnames(df_raw)[1:5] <- c("level_1", "level_2", "img_class_name", "desc_general", "desc_fcc")
# # 
# # # Clean metadata: forward fill Level 1 to establish the parent-child hierarchy
# # df_defs <- df_raw %>%
# #   mutate(level_1 = na_if(level_1, "")) %>%
# #   fill(level_1) %>%
# #   # Filter rows that have a valid mapping to image filenames
# #   filter(!is.na(img_class_name) & img_class_name != "")
# # 
# # # 2. IMAGE FILENAME PARSING
# # parse_files <- function(files) {
# #   data.frame(filename = files) %>%
# #     mutate(
# #       class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
# #       sample_num = str_extract(filename, "\\d+"),
# #       rest = str_extract(filename, "(?<=\\d_).*"),
# #       region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
# #       type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
# #       region_label = str_to_title(str_replace_all(region_id, "_", " "))
# #     )
# # }
# # 
# # file_data <- parse_files(all_files)
# # 
# # # 3. UI
# # ui <- fluidPage(
# #   theme = bs_theme(version = 5, bootswatch = "flatly"),
# #   titlePanel("IOLN Classification Explorer"),
# #   
# #   sidebarLayout(
# #     sidebarPanel(
# #       selectInput("l1_input", "Select Level 1 Category:", 
# #                   choices = sort(unique(df_defs$level_1))),
# #       uiOutput("l2_select_ui"),
# #       uiOutput("region_select_ui"),
# #       hr(),
# #       helpText("Images are grouped by Sample ID. Spectral and Ecological descriptions are synced from CSV.")
# #     ),
# #     
# #     mainPanel(
# #       # Definitions Section
# #       uiOutput("definition_card"),
# #       hr(),
# #       # Grouped Gallery (Row per Sample)
# #       uiOutput("sample_grid")
# #     )
# #   )
# # )
# # 
# # # 4. SERVER
# # server <- function(input, output, session) {
# #   
# #   output$l2_select_ui <- renderUI({
# #     req(input$l1_input)
# #     l2_choices <- df_defs %>%
# #       filter(level_1 == input$l1_input) %>%
# #       select(level_2, img_class_name) %>%
# #       distinct()
# #     
# #     selectInput("l2_input", "Select Level 2 Class:", 
# #                 choices = setNames(l2_choices$img_class_name, l2_choices$level_2))
# #   })
# #   
# #   output$region_select_ui <- renderUI({
# #     req(input$l2_input)
# #     available <- file_data %>%
# #       filter(class_id == input$l2_input) %>%
# #       select(region_id, region_label) %>%
# #       distinct()
# #     
# #     selectInput("region_input", "Select Region:", 
# #                 choices = setNames(available$region_id, available$region_label))
# #   })
# #   
# #   # Updated Definition Card to include FCC description
# #   output$definition_card <- renderUI({
# #     req(input$l2_input)
# #     row_match <- df_defs %>% filter(img_class_name == input$l2_input) %>% slice(1)
# #     
# #     tagList(
# #       div(class = "p-4 mb-3 bg-light border rounded shadow-sm",
# #           tags$span(class = "badge bg-info mb-2", row_match$level_1),
# #           h3(row_match$level_2),
# #           h5("Ecological Definition", class = "mt-3 text-secondary"),
# #           p(row_match$desc_general),
# #           
# #           # New FCC Description Block
# #           h5("General FCC Interpretation", class = "mt-4 text-secondary"),
# #           div(style = "white-space: pre-wrap; background-color: #fdfdfd; padding: 10px; border-left: 4px solid #0dcaf0;",
# #               p(row_match$desc_fcc))
# #       )
# #     )
# #   })
# #   
# #   output$sample_grid <- renderUI({
# #     req(input$l2_input, input$region_input)
# #     current_set <- file_data %>%
# #       filter(class_id == input$l2_input, region_id == input$region_input)
# #     
# #     unique_samples <- sort(unique(current_set$sample_num))
# #     
# #     if (length(unique_samples) == 0) {
# #       return(div(class="alert alert-warning", "No imagery found for this class and region."))
# #     }
# #     
# #     tagList(
# #       lapply(unique_samples, function(s) {
# #         variations <- current_set %>% filter(sample_num == s)
# #         
# #         div(class = "sample-row mb-5 pb-4 border-bottom",
# #             h4(paste("Sample ID:", s), class = "text-primary mb-3"),
# #             fluidRow(
# #               lapply(1:nrow(variations), function(i) {
# #                 img <- variations[i, ]
# #                 column(width = 3,
# #                        div(class = "card h-100 shadow-sm",
# #                            tags$img(src = img$filename, class = "card-img-top", 
# #                                     style = "height: 200px; object-fit: cover;"),
# #                            div(class = "card-footer p-1 text-center bg-dark text-white",
# #                                tags$small(toupper(img$type)))
# #                        )
# #                 )
# #               })
# #             )
# #         )
# #       })
# #     )
# #   })
# # }
# # 
# # shinyApp(ui = ui, server = server)
# 
# 
# library(shiny)
# library(bslib)
# library(stringr)
# library(dplyr)
# library(tidyr)
# 
# # 1. LOAD DATA: Definitions and Image List
# img_dir <- "www/" 
# all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")
# 
# # Load Cleaned Definitions
# df_raw <- read.csv("classes_definitions.csv", stringsAsFactors = FALSE, check.names = FALSE)
# 
# # Standardize critical column names
# # Columns: Level 1, Level 2, Class_name_in_images, Eco Desc, FCC Desc, Texture Desc
# colnames(df_raw)[1:6] <- c("level_1", "level_2", "img_class_name", 
#                            "desc_general", "desc_fcc", "desc_texture")
# 
# # Clean metadata: forward fill Level 1 categories
# df_defs <- df_raw %>%
#   mutate(level_1 = na_if(level_1, "")) %>%
#   fill(level_1) %>%
#   filter(!is.na(img_class_name) & img_class_name != "")
# 
# # 2. IMAGE FILENAME PARSING
# parse_files <- function(files) {
#   data.frame(filename = files) %>%
#     mutate(
#       class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
#       sample_num = str_extract(filename, "\\d+"),
#       rest = str_extract(filename, "(?<=\\d_).*"),
#       region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
#       type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
#       region_label = str_to_title(str_replace_all(region_id, "_", " "))
#     )
# }
# 
# file_data <- parse_files(all_files)
# 
# # 3. UI
# ui <- fluidPage(
#   theme = bs_theme(version = 5, bootswatch = "flatly"),
#   titlePanel(title = div("IOLN Class Definitions Explorer", style = "text-align: center;")),
#   
#   sidebarLayout(
#     sidebarPanel(
#       selectInput("l1_input", "Select Level 1 Category:", 
#                   choices = sort(unique(df_defs$level_1))),
#       uiOutput("l2_select_ui"),
#       uiOutput("region_select_ui"),
#       hr(),
#       # helpText("Images are grouped by Sample ID. All descriptions are synced from CSV.")
#     ),
#     
#     mainPanel(
#       # Definitions Section
#       uiOutput("definition_card"),
#       hr(),
#       # Grouped Gallery (Row per Sample)
#       uiOutput("sample_grid")
#     )
#   )
# )
# 
# # 4. SERVER
# server <- function(input, output, session) {
#   
#   output$l2_select_ui <- renderUI({
#     req(input$l1_input)
#     l2_choices <- df_defs %>%
#       filter(level_1 == input$l1_input) %>%
#       select(level_2, img_class_name) %>%
#       distinct()
#     
#     selectInput("l2_input", "Select Level 2 Class:", 
#                 choices = setNames(l2_choices$img_class_name, l2_choices$level_2))
#   })
#   
#   output$region_select_ui <- renderUI({
#     req(input$l2_input)
#     available <- file_data %>%
#       filter(class_id == input$l2_input) %>%
#       select(region_id, region_label) %>%
#       distinct()
#     
#     selectInput("region_input", "Select Region:", 
#                 choices = setNames(available$region_id, available$region_label))
#   })
#   
#   # Definition Card including Ecological, FCC, and Texture descriptions
#   output$definition_card <- renderUI({
#     req(input$l2_input)
#     row_match <- df_defs %>% filter(img_class_name == input$l2_input) %>% slice(1)
#     
#     tagList(
#       div(class = "p-4 mb-3 bg-light border rounded shadow-sm",
#           tags$span(class = "badge bg-info mb-2", row_match$level_1),
#           h3(row_match$level_2),
#           
#           h5("Ecological Definition", class = "mt-3 text-secondary"),
#           p(row_match$desc_general),
#           
#           h5("General FCC Interpretation", class = "mt-4 text-secondary"),
#           div(style = "white-space: pre-wrap; background-color: #fdfdfd; padding: 10px; border-left: 4px solid #0dcaf0; margin-bottom: 15px;",
#               p(row_match$desc_fcc)),
#           
#           # New Texture, Shape, and Pattern Block
#           h5("Texture, Shape and Pattern", class = "mt-4 text-secondary"),
#           div(style = "white-space: pre-wrap; background-color: #f8f9fa; padding: 10px; border-left: 4px solid #6c757d;",
#               p(row_match$desc_texture))
#       )
#     )
#   })
#   
#   output$sample_grid <- renderUI({
#     req(input$l2_input, input$region_input)
#     current_set <- file_data %>%
#       filter(class_id == input$l2_input, region_id == input$region_input)
#     
#     unique_samples <- sort(unique(current_set$sample_num))
#     
#     if (length(unique_samples) == 0) {
#       return(div(class="alert alert-warning", "No imagery found for this class and region."))
#     }
#     
#     tagList(
#       lapply(unique_samples, function(s) {
#         variations <- current_set %>% filter(sample_num == s)
#         
#         div(class = "sample-row mb-5 pb-4 border-bottom",
#             h4(paste("Sample ID:", s), class = "text-primary mb-3"),
#             fluidRow(
#               lapply(1:nrow(variations), function(i) {
#                 img <- variations[i, ]
#                 column(width = 3,
#                        div(class = "card h-100 shadow-sm",
#                            tags$img(src = img$filename, class = "card-img-top", 
#                                     style = "height: 200px; object-fit: cover;"),
#                            div(class = "card-footer p-1 text-center bg-dark text-white",
#                                tags$small(toupper(img$type)))
#                        )
#                 )
#               })
#             )
#         )
#       })
#     )
#   })
# }
# 
# shinyApp(ui = ui, server = server)

library(shiny)
library(bslib)
library(stringr)
library(dplyr)
library(tidyr)

# 1. LOAD DATA: Definitions and Image List
img_dir <- "www/" 
all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")

# Load Cleaned Definitions
df_raw <- read.csv("classes_definitions.csv", stringsAsFactors = FALSE, check.names = FALSE)

# Standardize critical column names
colnames(df_raw)[1:6] <- c("level_1", "level_2", "img_class_name", 
                           "desc_general", "desc_fcc", "desc_texture")

# Clean metadata: forward fill Level 1 categories
df_defs <- df_raw %>%
  mutate(level_1 = na_if(level_1, "")) %>%
  fill(level_1) %>%
  filter(!is.na(img_class_name) & img_class_name != "")

# 2. IMAGE FILENAME PARSING
parse_files <- function(files) {
  data.frame(filename = files) %>%
    mutate(
      class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
      sample_num = str_extract(filename, "\\d+"),
      rest = str_extract(filename, "(?<=\\d_).*"),
      region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
      type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
      region_label = str_to_title(str_replace_all(region_id, "_", " "))
    )
}

file_data <- parse_files(all_files)

# 3. UI
ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  titlePanel("IOLN Class Definitions Explorer"),
  sidebarLayout(
    sidebarPanel(
      selectInput("l1_input", "Select Level 1 Category:", 
                  choices = sort(unique(df_defs$level_1))),
      uiOutput("l2_select_ui"),
      uiOutput("region_select_ui"),
      hr(),
      # helpText("Ecological definition is at the top; FCC and Texture interpretations follow the samples.")
    ),
    
    mainPanel(
      # Top Section: Ecological Definition
      uiOutput("eco_definition_card"),
      hr(),
      
      # Middle Section: Grouped Gallery (Row per Sample)
      uiOutput("sample_grid"),
      
      # Bottom Section: Spectral & Structural Interpretations
      uiOutput("fcc_texture_card")
    )
  )
)

# 4. SERVER
server <- function(input, output, session) {
  
  output$l2_select_ui <- renderUI({
    req(input$l1_input)
    l2_choices <- df_defs %>%
      filter(level_1 == input$l1_input) %>%
      select(level_2, img_class_name) %>%
      distinct()
    
    selectInput("l2_input", "Select Level 2 Class:", 
                choices = setNames(l2_choices$img_class_name, l2_choices$level_2))
  })
  
  output$region_select_ui <- renderUI({
    req(input$l2_input)
    available <- file_data %>%
      filter(class_id == input$l2_input) %>%
      select(region_id, region_label) %>%
      distinct()
    
    selectInput("region_input", "Select Region:", 
                choices = setNames(available$region_id, available$region_label))
  })
  
  # Card 1: Ecological Definition (Stays at the Top)
  output$eco_definition_card <- renderUI({
    req(input$l2_input)
    row_match <- df_defs %>% filter(img_class_name == input$l2_input) %>% slice(1)
    
    div(class = "p-4 mb-3 bg-light border rounded shadow-sm",
        tags$span(class = "badge bg-info mb-2", row_match$level_1),
        h3(row_match$level_2),
        h5("Ecological Definition", class = "mt-3 text-secondary"),
        p(row_match$desc_general)
    )
  })
  
  # Image Gallery Section
  output$sample_grid <- renderUI({
    req(input$l2_input, input$region_input)
    current_set <- file_data %>%
      filter(class_id == input$l2_input, region_id == input$region_input)
    
    unique_samples <- sort(unique(current_set$sample_num))
    
    if (length(unique_samples) == 0) {
      return(div(class="alert alert-warning", "No imagery found for this class and region."))
    }
    
    tagList(
      lapply(unique_samples, function(s) {
        variations <- current_set %>% filter(sample_num == s)
        
        div(class = "sample-row mb-5 pb-4 border-bottom",
            h4(paste("Sample ID:", s), class = "text-primary mb-3"),
            fluidRow(
              lapply(1:nrow(variations), function(i) {
                img <- variations[i, ]
                column(width = 3,
                       div(class = "card h-100 shadow-sm",
                           tags$img(src = img$filename, class = "card-img-top", 
                                    style = "height: 200px; object-fit: cover;"),
                           div(class = "card-footer p-1 text-center bg-dark text-white",
                               tags$small(toupper(img$type)))
                       )
                )
              })
            )
        )
      })
    )
  })
  
  # Card 2: FCC & Texture (Now at the Bottom)
  output$fcc_texture_card <- renderUI({
    req(input$l2_input)
    row_match <- df_defs %>% filter(img_class_name == input$l2_input) %>% slice(1)
    
    div(class = "p-4 mt-4 bg-light border rounded shadow-sm",
        h5("General FCC Interpretation", class = "text-secondary"),
        div(style = "white-space: pre-wrap; background-color: #fdfdfd; padding: 15px; border-left: 4px solid #0dcaf0; margin-bottom: 25px;",
            p(row_match$desc_fcc)),
        
        h5("Texture, Shape and Pattern", class = "text-secondary"),
        div(style = "white-space: pre-wrap; background-color: #f8f9fa; padding: 15px; border-left: 4px solid #6c757d;",
            p(row_match$desc_texture))
    )
  })
}

shinyApp(ui = ui, server = server)