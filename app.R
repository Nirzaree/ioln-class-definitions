# # library(shiny)
# # library(bslib)
# # library(stringr)
# # library(dplyr)
# # library(tidyr)
# # 
# # # 1. LOAD DATA: Read the cleaned CSV and list images
# # # Images should be in a folder named 'www/' relative to app.R
# # img_dir <- "www/" 
# # all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")
# # 
# # # Load Class Definitions (Headers: Level 1, Level 2, Description Ecological - general)
# # df_defs <- read.csv("classes_definitions.csv", stringsAsFactors = FALSE, check.names = FALSE)
# # colnames(df_defs)[1:3] <- c("level_1", "level_2", "desc_general")
# # 
# # # 2. IMAGE FILENAME PARSING
# # # Logic for: classname_samplenumber_region_imagetype.png
# # # Matches multi-word classes/regions and extracts the numeric sample
# # parse_files <- function(files) {
# #   data.frame(filename = files) %>%
# #     mutate(
# #       # Class: Text before the first number sequence (e.g., 'mosaic_of_use')
# #       class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
# #       
# #       # Sample: The first numeric sequence (e.g., '116')
# #       sample_num = str_extract(filename, "\\d+"),
# #       
# #       # Extract everything after the sample number
# #       rest = str_extract(filename, "(?<=\\d_).*"),
# #       
# #       # Region: Text between sample number and the imagery suffix
# #       region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
# #       
# #       # Imagery Type (e.g., 'fcc543', 'rgb', 'basemap')
# #       type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
# #       
# #       # Create readable labels for UI
# #       class_label = str_to_title(str_replace_all(class_id, "_", " ")),
# #       region_label = str_to_title(str_replace_all(region_id, "_", " "))
# #     )
# # }
# # 
# # file_data <- parse_files(all_files)
# # 
# # # 3. UI
# # ui <- fluidPage(
# #   theme = bs_theme(version = 5, bootswatch = "flatly"),
# #   titlePanel("IOLN Class definitions"),
# #   
# #   sidebarLayout(
# #     sidebarPanel(
# #       # Dropdown for Class
# #       selectInput("class_input", "Select Class:", 
# #                   choices = setNames(sort(unique(file_data$class_id)), 
# #                                      sort(unique(file_data$class_label)))),
# #       
# #       # Dynamic dropdown for Regions
# #       uiOutput("region_select_ui"),
# #       
# #       hr(),
# #       helpText("Images are grouped by Sample ID. Definitions are pulled from your CSV.")
# #     ),
# #     
# #     mainPanel(
# #       # Dynamic Class Definition Section
# #       uiOutput("definition_card"),
# #       hr(),
# #       # Row-based Sample Gallery
# #       uiOutput("sample_grid")
# #     )
# #   )
# # )
# # 
# # # 4. SERVER
# # server <- function(input, output, session) {
# #   
# #   # Filter available regions based on the selected class
# #   output$region_select_ui <- renderUI({
# #     req(input$class_input)
# #     available <- file_data %>%
# #       filter(class_id == input$class_input) %>%
# #       select(region_id, region_label) %>%
# #       distinct()
# #     
# #     selectInput("region_input", "Select Region:", 
# #                 choices = setNames(available$region_id, available$region_label))
# #   })
# #   
# #   # DYNAMIC DEFINITION: Fuzzy match filename class to CSV Level 2
# #   output$definition_card <- renderUI({
# #     req(input$class_input)
# #     
# #     # Try to find a match in the Level 2 column using the filename prefix
# #     row_match <- df_defs %>%
# #       filter(grepl(input$class_input, level_2, ignore.case = TRUE) | 
# #                grepl(str_replace_all(input$class_input, "_", " "), level_2, ignore.case = TRUE)) %>%
# #       slice(1)
# #     
# #     if(nrow(row_match) > 0) {
# #       div(class = "p-4 mb-4 bg-light border rounded shadow-sm",
# #           tags$span(class = "badge bg-info mb-2", row_match$level_1),
# #           h3(row_match$level_2),
# #           p(class = "lead", row_match$desc_general)
# #       )
# #     } else {
# #       div(class = "alert alert-secondary", "No matching definition found in classes_definitions.csv")
# #     }
# #   })
# #   
# #   # GALLERY: One row per unique Sample Number
# #   output$sample_grid <- renderUI({
# #     req(input$class_input, input$region_input)
# #     
# #     # Filter for the class/region combination
# #     current_set <- file_data %>%
# #       filter(class_id == input$class_input, region_id == input$region_input)
# #     
# #     unique_samples <- sort(unique(current_set$sample_num))
# #     
# #     if (length(unique_samples) == 0) return(div("No imagery found."))
# #     
# #     # Generate a horizontal row for every Sample ID
# #     tagList(
# #       lapply(unique_samples, function(s) {
# #         # Find all spectral/map variations for this specific coordinate
# #         variations <- current_set %>% filter(sample_num == s)
# #         
# #         div(class = "mb-5 pb-4 border-bottom",
# #             h4(paste("Sample ID:", s), class = "text-primary mb-3"),
# #             fluidRow(
# #               lapply(1:nrow(variations), function(i) {
# #                 img <- variations[i, ]
# #                 column(width = 3, # 4 images per row
# #                        div(class = "card h-100 shadow-sm",
# #                            tags$img(src = img$filename, class = "card-img-top", 
# #                                     style = "height: 180px; object-fit: cover;"),
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
# library(shiny)
# library(bslib)
# library(stringr)
# library(dplyr)
# library(tidyr)
# 
# # 1. LOAD DATA: Definitions and Image List
# # Ensure images are in a folder named 'www/' relative to this script
# img_dir <- "www/" 
# all_files <- list.files(img_dir, pattern = "\\.(png|jpg|jpeg)$")
# 
# # Load Cleaned Definitions
# df_raw <- read.csv("classes_definitions.csv", stringsAsFactors = FALSE, check.names = FALSE)
# colnames(df_raw)[1:3] <- c("level_1", "level_2", "desc_general")
# 
# # Clean metadata: forward fill Level 1 to establish hierarchy
# df_defs <- df_raw %>%
#   mutate(level_1 = na_if(level_1, "")) %>%
#   fill(level_1) %>%
#   filter(!is.na(level_2) & level_2 != "")
# 
# # 2. IMAGE FILENAME PARSING
# # Pattern: classname_samplenumber_region_imagetype.png
# parse_files <- function(files) {
#   data.frame(filename = files) %>%
#     mutate(
#       # Extract Class: Text before the first number sequence
#       class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
#       # Sample: The first numeric sequence
#       sample_num = str_extract(filename, "\\d+"),
#       # Remainder of the string
#       rest = str_extract(filename, "(?<=\\d_).*"),
#       # Region: Text between sample number and imagery suffix
#       region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
#       # Imagery Type (e.g., 'fcc543', 'rgb', 'basemap')
#       type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
#       # Human-readable label for region
#       region_label = str_to_title(str_replace_all(region_id, "_", " "))
#     )
# }
# 
# file_data <- parse_files(all_files)
# 
# # 3. UI
# ui <- fluidPage(
#   theme = bs_theme(version = 5, bootswatch = "flatly"),
#   titlePanel("IOLN Classification Explorer"),
#   
#   sidebarLayout(
#     sidebarPanel(
#       # Level 1 Dropdown
#       selectInput("l1_input", "Select Level 1 Category:", 
#                   choices = sort(unique(df_defs$level_1))),
#       
#       # Level 2 Dropdown (Updated dynamically)
#       uiOutput("l2_select_ui"),
#       
#       # Region Dropdown (Updated dynamically based on L2)
#       uiOutput("region_select_ui"),
#       
#       hr(),
#       helpText("Each row shows all spectral variations for a single Sample ID.")
#     ),
#     
#     mainPanel(
#       # Definition Card from CSV
#       uiOutput("definition_card"),
#       hr(),
#       # Grouped Gallery
#       uiOutput("sample_grid")
#     )
#   )
# )
# 
# # 4. SERVER
# server <- function(input, output, session) {
#   
#   # Update Level 2 choices based on Level 1
#   output$l2_select_ui <- renderUI({
#     req(input$l1_input)
#     l2_choices <- df_defs %>%
#       filter(level_1 == input$l1_input) %>%
#       pull(level_2) %>%
#       sort()
#     
#     selectInput("l2_input", "Select Level 2 Class:", choices = l2_choices)
#   })
#   
#   # Update Regions based on Level 2
#   output$region_select_ui <- renderUI({
#     req(input$l2_input)
#     # Fuzzy match Level 2 name to filename class_id
#     clean_l2 <- tolower(str_replace_all(input$l2_input, "[^a-zA-Z0-9]", ""))
#     
#     available <- file_data %>%
#       filter(grepl(clean_l2, tolower(str_replace_all(class_id, "_", "")), fixed = TRUE) |
#                tolower(str_replace_all(class_id, "_", "")) %in% clean_l2) %>%
#       select(region_id, region_label) %>%
#       distinct()
#     
#     selectInput("region_input", "Select Region:", 
#                 choices = setNames(available$region_id, available$region_label))
#   })
#   
#   # Display CSV Description
#   output$definition_card <- renderUI({
#     req(input$l2_input)
#     row_match <- df_defs %>% filter(level_2 == input$l2_input) %>% slice(1)
#     
#     div(class = "p-4 mb-4 bg-light border rounded shadow-sm",
#         tags$span(class = "badge bg-info mb-2", row_match$level_1),
#         h3(row_match$level_2),
#         p(class = "lead", row_match$desc_general)
#     )
#   })
#   
#   # Visual Gallery: One Row per Sample ID
#   output$sample_grid <- renderUI({
#     req(input$l2_input, input$region_input)
#     
#     # Identify images matching the selection
#     clean_l2 <- tolower(str_replace_all(input$l2_input, "[^a-zA-Z0-9]", ""))
#     current_set <- file_data %>%
#       filter(region_id == input$region_input) %>%
#       filter(grepl(clean_l2, tolower(str_replace_all(class_id, "_", "")), fixed = TRUE) |
#                tolower(str_replace_all(class_id, "_", "")) %in% clean_l2)
#     
#     unique_samples <- sort(unique(current_set$sample_num))
#     
#     if (length(unique_samples) == 0) return(div("No imagery found for this class in the selected region."))
#     
#     tagList(
#       lapply(unique_samples, function(s) {
#         # Get all variations (RGB, FCC, Basemap) for this sample
#         variations <- current_set %>% filter(sample_num == s)
#         
#         div(class = "sample-row mb-5 pb-4 border-bottom",
#             h4(paste("Sample ID:", s), class = "text-primary mb-3"),
#             fluidRow(
#               lapply(1:nrow(variations), function(i) {
#                 img <- variations[i, ]
#                 column(width = 3, # Shows 4 variations across
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

# Standardize critical column names from your CSV
colnames(df_raw)[1:4] <- c("level_1", "level_2", "img_class_name", "desc_general")

# Clean metadata: forward fill Level 1 to establish the parent-child hierarchy
df_defs <- df_raw %>%
  mutate(level_1 = na_if(level_1, "")) %>%
  fill(level_1) %>%
  # Filter rows that have a valid mapping to image filenames
  filter(!is.na(img_class_name) & img_class_name != "")

# 2. IMAGE FILENAME PARSING
# Pattern: classname_samplenumber_region_imagetype.png
parse_files <- function(files) {
  data.frame(filename = files) %>%
    mutate(
      # Extract Class: Text before the first number sequence
      class_id = str_extract(filename, "^.*?(?=_\\d+_)"),
      # Sample Number
      sample_num = str_extract(filename, "\\d+"),
      # Remaining part of the string
      rest = str_extract(filename, "(?<=\\d_).*"),
      # Region: Text between sample number and imagery suffix
      region_id = str_replace(rest, "_(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)\\..*$", ""),
      # Imagery Type
      type = str_extract(rest, "(fcc[0-9]{3}Dry|fcc[0-9]{3}|rgb|basemap)"),
      # Readable labels
      region_label = str_to_title(str_replace_all(region_id, "_", " "))
    )
}

file_data <- parse_files(all_files)

# 3. UI
ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  titlePanel("IOLN Classification Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      # Level 1 Dropdown
      selectInput("l1_input", "Select Level 1 Category:", 
                  choices = sort(unique(df_defs$level_1))),
      
      # Level 2 Dropdown (Filtered by Level 1)
      uiOutput("l2_select_ui"),
      
      # Region Dropdown (Filtered by Selection)
      uiOutput("region_select_ui"),
      
      hr(),
      tags$p(strong("Mapping Rule:")),
      tags$small("Linking filename prefix to CSV column:"),
      tags$code("Class_name_in_images")
    ),
    
    mainPanel(
      # Definition Card
      uiOutput("definition_card"),
      hr(),
      # Grouped Gallery (Row per Sample)
      uiOutput("sample_grid")
    )
  )
)

# 4. SERVER
server <- function(input, output, session) {
  
  # Update Level 2 choices based on Level 1
  output$l2_select_ui <- renderUI({
    req(input$l1_input)
    l2_choices <- df_defs %>%
      filter(level_1 == input$l1_input) %>%
      select(level_2, img_class_name) %>%
      distinct()
    
    # We use the formal Level 2 name for the UI, but store the img_class_name for logic
    selectInput("l2_input", "Select Level 2 Class:", 
                choices = setNames(l2_choices$img_class_name, l2_choices$level_2))
  })
  
  # Update Regions based on selected class mapping
  output$region_select_ui <- renderUI({
    req(input$l2_input)
    
    available <- file_data %>%
      filter(class_id == input$l2_input) %>%
      select(region_id, region_label) %>%
      distinct()
    
    selectInput("region_input", "Select Region:", 
                choices = setNames(available$region_id, available$region_label))
  })
  
  # Display CSV Description dynamically
  output$definition_card <- renderUI({
    req(input$l2_input)
    row_match <- df_defs %>% filter(img_class_name == input$l2_input) %>% slice(1)
    
    div(class = "p-4 mb-4 bg-light border rounded shadow-sm",
        tags$span(class = "badge bg-info mb-2", row_match$level_1),
        h3(row_match$level_2),
        p(class = "lead", row_match$desc_general)
    )
  })
  
  # Visual Gallery: One Row per Sample ID
  output$sample_grid <- renderUI({
    req(input$l2_input, input$region_input)
    
    # Filter images matching exact Class and Region
    current_set <- file_data %>%
      filter(class_id == input$l2_input, region_id == input$region_input)
    
    unique_samples <- sort(unique(current_set$sample_num))
    
    if (length(unique_samples) == 0) {
      return(div(class="alert alert-warning", "No imagery found for this class and region."))
    }
    
    tagList(
      lapply(unique_samples, function(s) {
        # Group variations (RGB, FCCs, Basemap) for this sample
        variations <- current_set %>% filter(sample_num == s)
        
        div(class = "sample-row mb-5 pb-4 border-bottom",
            h4(paste("Sample ID:", s), class = "text-primary mb-3"),
            fluidRow(
              lapply(1:nrow(variations), function(i) {
                img <- variations[i, ]
                column(width = 3, # Show up to 4 variations side-by-side
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
}

shinyApp(ui = ui, server = server)